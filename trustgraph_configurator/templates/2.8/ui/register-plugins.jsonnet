{

    with:: function(key, value)
        if key == "add-demos" then
            self + {
                "ui-plugins" +:: {
                    demos +: value,
                },
            }
        else if key == "add-workflows" then
            self + {
                "ui-plugins" +:: {
                    workflows +: value,
                },
            }
        else if key == "replace-demos" then
            self + {
                "ui-plugins" +:: {
                    demos: value,
                },
            }
        else if key == "replace-workflows" then
            self + {
                "ui-plugins" +:: {
                    workflows: value,
                },
            }
        else if key == "bundle" then
            self + {
                "ui-bundle" +:: value,
            }
        else
            error "register-plugins: unknown key '" + key + "'",

}
