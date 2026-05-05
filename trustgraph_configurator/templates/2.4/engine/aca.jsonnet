// ARM template engine targeting Azure Container Apps (ACA).

// ACA Consumption plan only accepts a fixed grid of (cpu, memory)
// pairs where memory == cpu * 2 Gi. Patterns request values like
// "0.5"/"128M" that don't fit; we round up to the smallest valid
// pair that satisfies both axes.
local acaSizes = [
    { cpu: 0.25, memGib: 0.5 },
    { cpu: 0.5,  memGib: 1.0 },
    { cpu: 0.75, memGib: 1.5 },
    { cpu: 1.0,  memGib: 2.0 },
    { cpu: 1.25, memGib: 2.5 },
    { cpu: 1.5,  memGib: 3.0 },
    { cpu: 1.75, memGib: 3.5 },
    { cpu: 2.0,  memGib: 4.0 },
];

local parseCpu = function(c)
    if std.isNumber(c) then c
    else if std.endsWith(c, "m") then
        std.parseJson(std.substr(c, 0, std.length(c) - 1)) / 1000.0
    else std.parseJson(c);

// M and Mi (and G/Gi) are treated as equivalent here - the rounding
// step absorbs the small discrepancy.
local parseMemGib = function(m)
    if std.isNumber(m) then m
    else if std.endsWith(m, "Gi") then
        std.parseJson(std.substr(m, 0, std.length(m) - 2))
    else if std.endsWith(m, "G") then
        std.parseJson(std.substr(m, 0, std.length(m) - 1))
    else if std.endsWith(m, "Mi") then
        std.parseJson(std.substr(m, 0, std.length(m) - 2)) / 1024
    else if std.endsWith(m, "M") then
        std.parseJson(std.substr(m, 0, std.length(m) - 1)) / 1024
    else 0;

local pickAcaSize = function(cpu, memGib)
    local fits = std.filter(
        function(s) s.cpu >= cpu && s.memGib >= memGib,
        acaSizes
    );
    if std.length(fits) > 0 then fits[0]
    else acaSizes[std.length(acaSizes) - 1];

// ARM parameter names allow letters/digits/underscores but not
// hyphens, so we underscore-encode the ACA secret name.
local toArmParam = function(s) std.strReplace(s, "-", "_");

{

    container:: function(name)
    {

        local container = self,

        name: name,
        ports: [],
        volumes: [],
        bindMounts: [],
        environment: [],
        secretRefs: [],

        with_image:: function(x) self + { image: x },

        with_user:: function(x) self + { uid: x },

        with_group:: function(x) self + { gid: x },

        with_supplemental_group:: function(x) self,

        with_privileged:: function(x) self,

        with_command:: function(x) self + { command: x },

        with_entrypoint:: function(x) self + { entrypoint: x },

        with_environment:: function(x) self + {
            environment: super.environment + [
                { name: v.key, value: v.value }
                for v in std.objectKeysValues(x)
            ],
        },

        with_limits:: function(c, m) self + {
            cpuLimit: c, memLimit: m,
        },

        with_reservations:: function(c, m) self + {
            cpuReservation: c, memReservation: m,
        },

        with_volume_mount::
            function(vol, mnt) self + {
                volumes: super.volumes + [
                    { volume: vol, mount: mnt }
                ],
            },

        with_bind_mount::
            function(src, dest) self + {
                bindMounts: super.bindMounts + [
                    { src: src, dest: dest }
                ],
            },

        with_port::
            function(src, dest, name) self + {
                ports: super.ports + [
                    { src: src, dest: dest, name: name }
                ],
            },

        with_env_var_secrets:: function(vars) self + {
            secretRefs: super.secretRefs + [
                {
                    envVar: v,
                    secretRef: vars.name + "-" + vars.keyMap[v],
                }
                for v in vars.variables
            ],
        },

        add:: function()
            local cpuRaw =
                if std.objectHas(container, "cpuLimit") then container.cpuLimit
                else if std.objectHas(container, "cpuReservation") then container.cpuReservation
                else "0.5";
            local memRaw =
                if std.objectHas(container, "memLimit") then container.memLimit
                else if std.objectHas(container, "memReservation") then container.memReservation
                else "1Gi";
            local size = pickAcaSize(parseCpu(cpuRaw), parseMemGib(memRaw));
            local secretEnv = [
                { name: r.envVar, secretRef: r.secretRef }
                for r in container.secretRefs
            ];
            local allEnv = container.environment + secretEnv;
            // SMB doesn't support POSIX byte-range locks (sqlite et al
            // fail without `nobrl`). uid/gid only included when the
            // pattern declares them via with_user/with_group; otherwise
            // CIFS defaults apply.
            local acaMountOpts =
                "nobrl"
                + (if std.objectHas(container, "uid")
                   then ",uid=" + container.uid else "")
                + (if std.objectHas(container, "gid")
                   then ",gid=" + container.gid else "");
            local azureFileVolumes = [
                {
                    name: v.volume.name,
                    storageType: "AzureFile",
                    storageName: v.volume.name,
                    mountOptions: acaMountOpts,
                }
                for v in container.volumes
                if std.objectHasAll(v.volume, "kind")
                   && v.volume.kind == "azureFile"
            ];
            local azureFileDeps = [
                "[resourceId('Microsoft.App/managedEnvironments/storages', parameters('environmentName'), '" + v.volume.name + "')]"
                for v in container.volumes
                if std.objectHasAll(v.volume, "kind")
                   && v.volume.kind == "azureFile"
            ];
            [
            {
                type: "Microsoft.App/containerApps",
                apiVersion: "2024-03-01",
                name: container.name,
                location: "[parameters('location')]",
                dependsOn: [
                    "[resourceId('Microsoft.App/managedEnvironments', parameters('environmentName'))]",
                ] + azureFileDeps,
                properties: {
                    managedEnvironmentId:
                        "[resourceId('Microsoft.App/managedEnvironments', parameters('environmentName'))]",
                    configuration: {
                        activeRevisionsMode: "Single",
                    },
                    template: {
                        containers: [
                            {
                                name: container.name,
                                image: container.image,
                                resources: {
                                    cpu: size.cpu,
                                    memory: "" + size.memGib + "Gi",
                                },
                            } + (
                                if std.objectHas(container, "entrypoint") then
                                    (if std.isString(container.entrypoint) && container.entrypoint == "" then
                                        { command: [] }
                                    else if std.isArray(container.entrypoint) then
                                        { command: container.entrypoint }
                                    else
                                        { command: [container.entrypoint] }
                                    ) + (if std.objectHas(container, "command") then
                                        { args:
                                            if std.isArray(container.command)
                                            then container.command
                                            else [container.command]
                                        }
                                    else {})
                                else if std.objectHas(container, "command") then
                                    { command:
                                        if std.isArray(container.command)
                                        then container.command
                                        else [container.command]
                                    }
                                else {}
                            ) + (
                                if std.length(allEnv) > 0 then
                                    { env: allEnv }
                                else {}
                            ) + (
                                local mounts = [
                                    {
                                        volumeName: v.volume.name,
                                        mountPath: v.mount,
                                    }
                                    for v in container.volumes
                                    if std.objectHasAll(v.volume, "kind")
                                       && (v.volume.kind == "configVolume"
                                           || v.volume.kind == "secretVolume"
                                           || v.volume.kind == "azureFile")
                                ];
                                if std.length(mounts) > 0
                                then { volumeMounts: mounts }
                                else {}
                            ),
                        ],
                        scale: {
                            minReplicas: 1,
                            maxReplicas: 1,
                        },
                    } + (
                        if std.length(azureFileVolumes) > 0 then
                            { volumes: azureFileVolumes }
                        else {}
                    ),
                },
            },
        ],

    },

    internalService:: self.service,

    // service emits a sentinel marker rather than a free-standing ARM
    // resource; ACA ingress is a property of the containerApp, not a
    // separate resource. `package()` recognises the marker and folds
    // it into the matching containerApp before output.
    service:: function(containers)
    {

        local service = self,

        name: containers.name,
        ports: [],
        external: false,

        with_port::
            function(src, dest, name) self + {
                ports: super.ports + [
                    { src: src, dest: dest, name: name }
                ],
            },

        with_external:: function() self + { external: true },

        add:: function()
            if std.length(service.ports) == 0 then []
            else [{
                _aca_kind: "ingress",
                targetApp: service.name,
                ports: service.ports,
                external: service.external,
            }],

    },

    volume:: function(name)
    {

        local volume = self,

        name: name,
        kind:: "azureFile",

        with_size:: function(size) self + { size: size },

        add:: function() [{
            _aca_kind: "azureFileVolume",
            name: volume.name,
            size: if std.objectHas(volume, "size") then volume.size else "1Gi",
        }],

        volRef:: function() { name: volume.name },

    },

    configVolume:: function(name, dir, parts)
    {

        local volume = self,

        name: name,
        kind:: "configVolume",

        with_size:: function(size) self + { size: size },

        add:: function() [{
            _aca_kind: "configVolume",
            name: volume.name,
            parts: parts,
        }],

        volRef:: function() { name: volume.name },

    },

    secretVolume:: function(name, dir, parts)
    {

        local volume = self,

        name: name,
        kind:: "secretVolume",

        with_size:: function(size) self + { size: size },

        add:: function() [{
            _aca_kind: "secretVolume",
            name: volume.name,
            parts: parts,
        }],

        volRef:: function() { name: volume.name },

    },

    envSecrets:: function(name)
    {

        local volume = self,

        name: name,
        variables: [],
        keyMap: {},

        with_size:: function(size) self,

        with_env_var::
            function(name, key) self + {
                variables: super.variables + [name],
                keyMap: super.keyMap + { [name]: key },
            },

        add:: function() [],

        volRef:: function() { name: volume.name },

    },

    containers:: function(name, containers)
    {

        local cont = self,

        name: name,
        containers: containers,

        add:: function() std.flattenArrays(
            [ c.add() for c in cont.containers ]
        ),

    },

    resources:: function(res)
        std.flattenArrays([ c.add() for c in res ]),

    package:: function(patterns)
        local rawList = std.flattenArrays([
            p.create(self) for p in std.objectValues(patterns)
        ]);
        local isMarker = function(r) std.objectHas(r, "_aca_kind");
        local markers = std.filter(isMarker, rawList);
        local arms = std.filter(function(r) !isMarker(r), rawList);
        local ingressByApp = {
            [m.targetApp]: m
            for m in markers
            if m._aca_kind == "ingress"
        };
        // ACA TCP ingress requires a unique exposedPort per env when
        // exposedPort is set; we leave it unset so it defaults to
        // targetPort. Apps with overlapping targetPorts (e.g. multiple
        // services exposing :8000 metrics) will conflict at deploy
        // time - that's a step-3 concern.
        local applyIngress = function(arm)
            if std.objectHas(arm, "type")
               && arm.type == "Microsoft.App/containerApps"
               && std.objectHas(ingressByApp, arm.name) then
                local m = ingressByApp[arm.name];
                local first = m.ports[0];
                local rest = m.ports[1:];
                arm + {
                    properties+: {
                        configuration+: {
                            ingress: {
                                external: m.external,
                                transport: if m.external then "http" else "tcp",
                                targetPort: first.dest,
                            } + (
                                if std.length(rest) > 0 then {
                                    // ACA only allows the primary
                                    // targetPort to be external on a
                                    // default (non-custom-VNET) env;
                                    // additional ports must be internal.
                                    additionalPortMappings: [
                                        {
                                            external: false,
                                            targetPort: p.dest,
                                        }
                                        for p in rest
                                    ],
                                } else {}
                            ),
                        },
                    },
                }
            else arm;
        // configVolume parts are mounted via ACA Secret-type volumes:
        // each file becomes an entry in `configuration.secrets`, and a
        // `template.volumes[]` entry of storageType=Secret references
        // them with the original filenames as paths. Read-only mount.
        local cfgVolByName = {
            [m.name]: m
            for m in markers
            if m._aca_kind == "configVolume"
               || m._aca_kind == "secretVolume"
        };
        local sanitize = function(s)
            std.strReplace(std.strReplace(s, ".", "-"), "_", "-");
        local applyConfigVolumes = function(arm)
            if std.objectHas(arm, "type")
               && arm.type == "Microsoft.App/containerApps"
               && std.length(arm.properties.template.containers) > 0
               && std.objectHas(
                    arm.properties.template.containers[0], "volumeMounts"
               ) then
                local mounts =
                    arm.properties.template.containers[0].volumeMounts;
                local cfgs = [
                    cfgVolByName[m.volumeName]
                    for m in mounts
                    if std.objectHas(cfgVolByName, m.volumeName)
                ];
                if std.length(cfgs) == 0 then arm
                else
                    // configVolume content stays inline; secretVolume
                    // content is lifted into a per-file secureString
                    // ARM parameter so the credential never sits in the
                    // template itself.
                    local secrets = std.flattenArrays([
                        [
                            {
                                name: cfg.name + "-" + sanitize(filename),
                                value:
                                    if cfg._aca_kind == "secretVolume" then
                                        "[parameters('"
                                        + toArmParam(
                                            cfg.name + "-" + sanitize(filename)
                                          )
                                        + "')]"
                                    else cfg.parts[filename],
                            }
                            for filename in std.objectFields(cfg.parts)
                        ]
                        for cfg in cfgs
                    ]);
                    local volumes = [
                        {
                            name: cfg.name,
                            storageType: "Secret",
                            secrets: [
                                {
                                    secretRef:
                                        cfg.name + "-" + sanitize(filename),
                                    path: filename,
                                }
                                for filename in std.objectFields(cfg.parts)
                            ],
                        }
                        for cfg in cfgs
                    ];
                    arm + {
                        properties+: {
                            configuration+: {
                                secrets+: secrets,
                            },
                            template+: {
                                volumes+: volumes,
                            },
                        },
                    }
            else arm;
        // envSecrets: each container's env entry with `secretRef` is
        // backed by a per-app entry in `configuration.secrets` whose
        // value is an ARM-parameter reference, plus a template-level
        // `parameters` declaration of type `secureString`. Operators
        // supply real values at deploy time.
        local appSecretRefs = function(arm)
            if std.objectHas(arm, "type")
               && arm.type == "Microsoft.App/containerApps"
               && std.length(arm.properties.template.containers) > 0
               && std.objectHas(
                    arm.properties.template.containers[0], "env"
               ) then
                std.filter(
                    function(e) std.objectHas(e, "secretRef"),
                    arm.properties.template.containers[0].env
                )
            else [];
        local applyEnvSecrets = function(arm)
            local refs = appSecretRefs(arm);
            if std.length(refs) == 0 then arm
            else
                local newSecrets = [
                    {
                        name: e.secretRef,
                        value: "[parameters('" + toArmParam(e.secretRef) + "')]",
                    }
                    for e in refs
                ];
                arm + {
                    properties+: {
                        configuration+: {
                            secrets+: newSecrets,
                        },
                    },
                };
        // AzureFile volumes are emitted directly by container.add()
        // (template.volumes + dependsOn), so package() only needs to
        // declare the template-scope storage account, file shares, and
        // env-storage registrations - that happens further below.
        local azureFileMarkers = [
            m for m in markers
            if m._aca_kind == "azureFileVolume"
        ];
        local appResources = std.map(
            applyEnvSecrets,
            std.map(applyConfigVolumes, std.map(applyIngress, arms))
        );
        local allSecretRefNames = std.set(std.flattenArrays([
            [e.secretRef for e in appSecretRefs(arm)]
            for arm in std.map(applyIngress, arms)
        ]));
        local secretParams = {
            [toArmParam(ref)]: { type: "secureString" }
            for ref in allSecretRefNames
        };
        local secretVolumeParts = std.set(std.flattenArrays([
            [
                m.name + "-" + sanitize(filename)
                for filename in std.objectFields(m.parts)
            ]
            for m in markers
            if m._aca_kind == "secretVolume"
        ]));
        local secretVolumeParams = {
            [toArmParam(p)]: { type: "secureString" }
            for p in secretVolumeParts
        };
        local externalApps = std.set([
            m.targetApp
            for m in markers
            if m._aca_kind == "ingress" && m.external
        ]);
        local outputs = {
            [toArmParam(app) + "_url"]: {
                type: "string",
                value:
                    "[concat('https://', reference(resourceId("
                    + "'Microsoft.App/containerApps', '"
                    + app
                    + "'), '2024-03-01').configuration.ingress.fqdn)]",
            }
            for app in externalApps
        };
        local quotaGib = function(s)
            local g = parseMemGib(s);
            if g < 100 then 100 else std.ceil(g);
        local storageAccount =
            if std.length(azureFileMarkers) > 0 then [{
                type: "Microsoft.Storage/storageAccounts",
                apiVersion: "2023-01-01",
                name: "[parameters('storageAccountName')]",
                location: "[parameters('location')]",
                kind: "FileStorage",
                sku: { name: "Premium_LRS" },
                properties: {
                    minimumTlsVersion: "TLS1_2",
                    allowBlobPublicAccess: false,
                },
            }] else [];
        local fileShares = [
            {
                type: "Microsoft.Storage/storageAccounts/fileServices/shares",
                apiVersion: "2023-01-01",
                name: "[concat(parameters('storageAccountName'), '/default/" + m.name + "')]",
                dependsOn: [
                    "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]",
                ],
                properties: {
                    shareQuota: quotaGib(m.size),
                    accessTier: "Premium",
                },
            }
            for m in azureFileMarkers
        ];
        local envStorages = [
            {
                type: "Microsoft.App/managedEnvironments/storages",
                apiVersion: "2024-03-01",
                name: "[concat(parameters('environmentName'), '/" + m.name + "')]",
                dependsOn: [
                    "[resourceId('Microsoft.App/managedEnvironments', parameters('environmentName'))]",
                    "[resourceId('Microsoft.Storage/storageAccounts/fileServices/shares', parameters('storageAccountName'), 'default', '" + m.name + "')]",
                ],
                properties: {
                    azureFile: {
                        accountName: "[parameters('storageAccountName')]",
                        accountKey: "[listKeys(resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName')), '2023-01-01').keys[0].value]",
                        shareName: m.name,
                        accessMode: "ReadWrite",
                    },
                },
            }
            for m in azureFileMarkers
        ];
        local logAnalyticsWorkspace = {
            type: "Microsoft.OperationalInsights/workspaces",
            apiVersion: "2022-10-01",
            name: "[variables('logAnalyticsWorkspaceName')]",
            location: "[parameters('location')]",
            properties: {
                sku: { name: "PerGB2018" },
                retentionInDays: 30,
            },
        };
        local managedEnvironment = {
            type: "Microsoft.App/managedEnvironments",
            apiVersion: "2024-03-01",
            name: "[parameters('environmentName')]",
            location: "[parameters('location')]",
            dependsOn: [
                "[resourceId('Microsoft.OperationalInsights/workspaces', variables('logAnalyticsWorkspaceName'))]",
            ],
            properties: {
                appLogsConfiguration: {
                    destination: "log-analytics",
                    logAnalyticsConfiguration: {
                        customerId: "[reference(resourceId('Microsoft.OperationalInsights/workspaces', variables('logAnalyticsWorkspaceName')), '2022-10-01').customerId]",
                        sharedKey: "[listKeys(resourceId('Microsoft.OperationalInsights/workspaces', variables('logAnalyticsWorkspaceName')), '2022-10-01').primarySharedKey]",
                    },
                },
            },
        };
        {
            "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
            contentVersion: "1.0.0.0",
            parameters: {
                location: {
                    type: "string",
                    defaultValue: "[resourceGroup().location]",
                },
                environmentName: {
                    type: "string",
                    defaultValue: "trustgraph-env",
                },
                storageAccountName: {
                    type: "string",
                    defaultValue: "[concat('tg', uniqueString(resourceGroup().id))]",
                },
            } + secretParams + secretVolumeParams,
            variables: {
                logAnalyticsWorkspaceName: "[concat(parameters('environmentName'), '-logs')]",
            },
            resources:
                [logAnalyticsWorkspace, managedEnvironment]
                + storageAccount + fileShares + envStorages
                + appResources,
            outputs: outputs,
        },

}
