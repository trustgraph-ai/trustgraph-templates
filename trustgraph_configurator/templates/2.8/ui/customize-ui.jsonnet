{

    with:: function(key, value)
        if key == "replace-components" then
            self + {
                "ui-components":: value,
            }
        else if key == "add-section" then
            self + {
                "ui-components" +:: [value],
            }
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
        else if key == "guidance" then
            self + {
                "ui-guidance" +:: value,
            }
        else if key == "bundle" then
            self + {
                "ui-bundle" +:: value,
            }
        else
            error "customize-ui: unknown key '" + key + "'",

}
