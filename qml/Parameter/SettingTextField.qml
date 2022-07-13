// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.0

import UM 1.1 as UM
import Cura 1.0 as Cura

SettingItem
{
    id: base
    property var focusItem: input

    property string textBeforeEdit
    property bool textHasChanged
    property bool focusGainedByClick: false
    onFocusReceived:
    {
        textHasChanged = false;
        textBeforeEdit = focusItem.text;

        if(!focusGainedByClick)
        {
            // select all text when tabbing through fields (but not when selecting a field with the mouse)
            focusItem.selectAll();
        }
    }
    enabled:// provider.properties.enabled == "True"
    {
        if (!Cura.ExtruderManager.activeExtruderStackId && machineExtruderCount.properties.value > 1)
        {
            // disable all controls on the global tab, except categories
            return model.type == "category"
        }
        return provider.properties.enabled == "True"
    }

    contents: Rectangle
    {
        id: control

        anchors.fill: parent

        radius: 3 * UM.Theme.getSize("default_margin").width/10
        border.width: 1 * UM.Theme.getSize("default_margin").width/10//Math.round(UM.Theme.getSize("default_lining").width)
        border.color:
        {
            if(!enabled)
            {
                return UM.Theme.getColor("color2")
            }
            switch(propertyProvider.properties.validationState)
            {
                case "ValidatorState.Exception":
                case "ValidatorState.MinimumError":
                case "ValidatorState.MaximumError":
                    return UM.Theme.getColor("color17");
                case "ValidatorState.MinimumWarning":
                case "ValidatorState.MaximumWarning":
                    return UM.Theme.getColor("color17");
            }
            //Validation is OK.
            if(hovered || input.activeFocus)
            {
                return UM.Theme.getColor("color16")
            }
            return UM.Theme.getColor("color2")
        }

        color: {
            if(!enabled)
            {
                return UM.Theme.getColor("color1")
            }
            else
            {
                return UM.Theme.getColor("color7")
            }

            /*switch(propertyProvider.properties.validationState)
            {
                case "ValidatorState.Exception":
                case "ValidatorState.MinimumError":
                case "ValidatorState.MaximumError":
                    return UM.Theme.getColor("setting_validation_error_background")
                case "ValidatorState.MinimumWarning":
                case "ValidatorState.MaximumWarning":
                    return UM.Theme.getColor("setting_validation_warning_background")
                case "ValidatorState.Valid":
                    return UM.Theme.getColor("setting_validation_ok")

                default:
                    return UM.Theme.getColor("setting_control")
            }*/
        }

        Rectangle
        {
            anchors.fill: parent;
            anchors.margins: Math.round(UM.Theme.getSize("default_lining").width);
            color: UM.Theme.getColor("setting_control_highlight")
            opacity: !control.hovered ? 0 : propertyProvider.properties.validationState == "ValidatorState.Valid" ? 1.0 : 0.35;
        }

        Label
        {
            anchors.right: parent.right
            anchors.rightMargin: Math.round(UM.Theme.getSize("setting_unit_margin").width)
            anchors.verticalCenter: parent.verticalCenter

            text: definition.unit
            renderType: Text.NativeRendering
            color: !enabled ? UM.Theme.getColor("color8") : UM.Theme.getColor("color4")
            font: UM.Theme.getFont("default")
        }

        TextInput
        {
            id: input

            anchors
            {
                left: parent.left
                leftMargin: Math.round(UM.Theme.getSize("setting_unit_margin").width)
                right: parent.right
                rightMargin: Math.round(UM.Theme.getSize("setting_unit_margin").width)
                verticalCenter: parent.verticalCenter
            }
            renderType: Text.NativeRendering

            Keys.onTabPressed:
            {
                base.setActiveFocusToNextSetting(true)
            }
            Keys.onBacktabPressed:
            {
                base.setActiveFocusToNextSetting(false)
            }

            Keys.onReleased:
            {
                if (text != textBeforeEdit)
                {
                    textHasChanged = true;
                }
                if (textHasChanged)
                {
                    propertyProvider.setPropertyValue("value", text)
                }
            }
            onEditingFinished:
            {
                propertyProvider.setPropertyValue("value", text)
            }

            onActiveFocusChanged:
            {
                if(activeFocus)
                {
                    base.focusReceived();
                }
                base.focusGainedByClick = false;
            }

            color: !enabled ? UM.Theme.getColor("color8") : UM.Theme.getColor("color4")
            font: UM.Theme.getFont("default");

            selectByMouse: true;

            maximumLength: (definition.type == "str" || definition.type == "[int]") ? -1 : 10;
            clip: true; //Hide any text that exceeds the width of the text box.

            validator: RegExpValidator { regExp: (definition.type == "[int]") ? /^\[?(\s*-?[0-9]{0,9}\s*,)*(\s*-?[0-9]{0,9})\s*\]?$/ : (definition.type == "int") ? /^-?[0-9]{0,10}$/ : (definition.type == "float") ? /^-?[0-9]{0,9}[.,]?[0-9]{0,10}$/ : /^.*$/ } // definition.type property from parent loader used to disallow fractional number entry

            Binding
            {
                target: input
                property: "text"
                value:  {
                    // Stacklevels
                    // 0: user  -> unsaved change
                    // 1: quality changes  -> saved change
                    // 2: quality
                    // 3: material  -> user changed material in materialspage
                    // 4: variant
                    // 5: machine_changes
                    // 6: machine
                    if ((base.resolve != "None" && base.resolve) && (stackLevel != 0) && (stackLevel != 1)) {
                        // We have a resolve function. Indicates that the setting is not settable per extruder and that
                        // we have to choose between the resolved value (default) and the global value
                        // (if user has explicitly set this).
                        return base.resolve;
                    } else {
                        return propertyProvider.properties.value;
                    }
                }
                when: !input.activeFocus
            }

            MouseArea
            {
                id: mouseArea
                anchors.fill: parent;

                cursorShape: Qt.IBeamCursor

                onPressed: {
                    if(!input.activeFocus) {
                        base.focusGainedByClick = true;
                        input.forceActiveFocus();
                    }
                    mouse.accepted = false;
                }
            }
        }
    }
}
