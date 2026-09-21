{

    with:: function(key, value)

        // --- components ---
        if key == "replace-components" then
            self + {
                "ui-components":: value,
            }
        else if key == "add-component" then
            self + {
                "ui-components" +:: [value],
            }

        // --- tabs bar ---
        else if key == "replace-tabs" then
            self + {
                "ui-tabs":: value,
            }
        else if key == "add-tab" then
            self + {
                "ui-tabs" +:: [value],
            }

        // --- routes ---
        else if key == "replace-routes" then
            self + {
                "ui-routes":: value,
            }
        else if key == "add-route" then
            self + {
                "ui-routes" +:: [value],
            }

        // --- navigation ---
        else if key == "replace-navigation" then
            self + {
                "ui-navigation":: value,
            }

        // --- tab grid configs ---
        else if key == "replace-tab-home" then
            self + {
                "ui-tab-home":: value,
            }
        else if key == "replace-tab-demos" then
            self + {
                "ui-tab-demos":: value,
            }
        else if key == "replace-tab-admin" then
            self + {
                "ui-tab-admin":: value,
            }
        else if key == "add-tab-home-card" then
            self + {
                "ui-tab-home" +:: {
                    cards +: [value],
                },
            }
        else if key == "add-tab-demos-card" then
            self + {
                "ui-tab-demos" +:: {
                    cards +: [value],
                },
            }
        else if key == "add-tab-admin-card" then
            self + {
                "ui-tab-admin" +:: {
                    cards +: [value],
                },
            }

        // --- action buttons ---
        else if key == "add-action-buttons" then
            self + {
                "ui-action-buttons" +:: {
                    global +: value,
                },
            }
        else if key == "replace-action-buttons" then
            self + {
                "ui-action-buttons" +:: {
                    global: value,
                },
            }

        // --- guidance ---
        else if key == "guidance" then
            self + {
                "ui-guidance" +:: value,
            }

        // --- grid tab (all-in-one) ---
        else if key == "add-grid-tab" then
            self + {
                "ui-tabs" +:: [{
                    label: value.label,
                    icon: value.icon,
                    target: "urn:tab:" + value.id,
                }],
                "ui-routes" +:: [{
                    target: "urn:tab:" + value.id,
                    component: value.id + "-grid",
                }],
                "ui-components" +:: [{
                    id: value.id + "-grid",
                    config: "/config/tabs/" + value.id + ".json",
                }],
                "ui-extra-tab-configs" +:: {
                    [value.id + ".json"]: value.tab,
                },
            }

        // --- bundle ---
        else if key == "bundle" then
            self + {
                "ui-bundle" +:: value,
            }

        else
            error "customize-ui: unknown key '" + key + "'",

}
