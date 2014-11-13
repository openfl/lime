
// This file is included directly in DirectFBStage.cpp, to reduce clutter

bool DirectFBKeyInputEventConvert(const DFBInputEvent &src, Event &dest)
{
    // Will track whether or not the key was the 'right' version rather than
    // the 'left' version
    bool left = true;

    // First set the NME Event's value to the key id

    // Handle a - z 
    if ((src.key_id >= DIKI_A) && (src.key_id <= DIKI_Z)) {
        dest.value = keyA + (src.key_id - DIKI_A);
    }
    // Handle 0 - 9
    else if ((src.key_id >= DIKI_0) && (src.key_id <= DIKI_9)) {
        dest.value = keyNUMBER_0 + (src.key_id - DIKI_0);
    }
    // Handle F1 - F12
    else if ((src.key_id >= DIKI_F1) && (src.key_id <= DIKI_F12)) {
        dest.value = keyF1 + (src.key_id - DIKI_F1);
    }
    // Handle number pad 0 - 9
    else if ((src.key_id >= DIKI_KP_0) && (src.key_id <= DIKI_KP_9)) {
        dest.value = keyNUMPAD_0 + (src.key_id - DIKI_KP_0);
    }
    // Handle everything else specially
    else {
        switch (src.key_id) {
        case DIKI_UNKNOWN:
            // Can't use this
            return false;
        case DIKI_SHIFT_L:
            left = false;
        case DIKI_SHIFT_R:
            dest.value = keySHIFT;
            break;
        case DIKI_CONTROL_L:
            left = false;
        case DIKI_CONTROL_R:
            dest.value = keyCONTROL;
            break;
        case DIKI_ALT_L:
        case DIKI_META_L:
        case DIKI_SUPER_L:
        case DIKI_HYPER_L:
            left = false;
        case DIKI_ALT_R:
        case DIKI_META_R:
        case DIKI_SUPER_R:
        case DIKI_HYPER_R:
            dest.value = keyALTERNATE;
            break;
        case DIKI_CAPS_LOCK:
            dest.value = keyCAPS_LOCK;
            break;
        case DIKI_NUM_LOCK:
        case DIKI_SCROLL_LOCK:
            // Unknown to NME
            return false;
        case DIKI_ESCAPE:
            dest.value = keyESCAPE;
            break;
        case DIKI_LEFT:
            dest.value = keyLEFT;
            break;
        case DIKI_RIGHT:
            dest.value = keyRIGHT;
            break;
        case DIKI_UP:
            dest.value = keyUP;
            break;
        case DIKI_DOWN:
            dest.value = keyDOWN;
            break;
        case DIKI_TAB:
            dest.value = keyTAB;
            break;
        case DIKI_ENTER:
            dest.value = keyENTER;
            break;
        case DIKI_SPACE:
            dest.value = keySPACE;
            break;
        case DIKI_BACKSPACE:
            dest.value = keyBACKSPACE;
            break;
        case DIKI_INSERT:
            dest.value = keyINSERT;
            break;
        case DIKI_DELETE:
            dest.value = keyDELETE;
            break;
        case DIKI_HOME:
            dest.value = keyHOME;
            break;
        case DIKI_END:
            dest.value = keyEND;
            break;
        case DIKI_PAGE_UP:
            dest.value = keyPAGE_UP;
            break;
        case DIKI_PAGE_DOWN:
            dest.value = keyPAGE_DOWN;
            break;
        case DIKI_PRINT:
        case DIKI_PAUSE:
            // Unknown to NME
            return false;
        case DIKI_QUOTE_LEFT:    /*  TLDE  */
            dest.value = keyQUOTE;
            break;
        case DIKI_MINUS_SIGN:    /*  AE11  */
            dest.value = keyMINUS;
            break;
        case DIKI_EQUALS_SIGN:   /*  AE12  */
            dest.value = keyEQUAL;
            break;
        case DIKI_BRACKET_LEFT:  /*  AD11  */
            dest.value = keyLEFTBRACKET;
            break;
        case DIKI_BRACKET_RIGHT: /*  AD12  */
            dest.value = keyRIGHTBRACKET;
            break;
        case DIKI_BACKSLASH:     /*  BKSL  */
            dest.value = keyBACKSLASH;
            break;
        case DIKI_SEMICOLON:     /*  AC10  */
            dest.value = keySEMICOLON;
            break;
        case DIKI_QUOTE_RIGHT:   /*  AC11  */
            dest.value = keyQUOTE;
            break;
        case DIKI_COMMA:         /*  AB08  */
            dest.value = keyCOMMA;
            break;
        case DIKI_PERIOD:        /*  AB09  */
            dest.value = keyPERIOD;
            break;
        case DIKI_SLASH:         /*  AB10  */
            dest.value = keySLASH;
            break;
        case DIKI_LESS_SIGN:     /*  103rd  */
            // Unknown to NME
            return false;
        case DIKI_KP_DIV:
            dest.value = keyNUMPAD_DIVIDE;
            break;
        case DIKI_KP_MULT:
            dest.value = keyNUMPAD_MULTIPLY;
            break;
        case DIKI_KP_MINUS:
            dest.value = keyNUMPAD_SUBTRACT;
            break;
        case DIKI_KP_PLUS:
            dest.value = keyNUMPAD_ADD;
            break;
        case DIKI_KP_ENTER:
            dest.value = keyNUMPAD_ENTER;
            break;
        case DIKI_KP_SPACE:
            dest.value = keySPACE;
            break;
        case DIKI_KP_TAB:
            dest.value = keyTAB;
            break;
        case DIKI_KP_F1:
        case DIKI_KP_F2:
        case DIKI_KP_F3:
        case DIKI_KP_F4:
        case DIKI_KP_EQUAL:
        case DIKI_KP_SEPARATOR:
            // Unknown to NME
            return false;
        case DIKI_KP_DECIMAL:
            dest.value = keyNUMPAD_DECIMAL;
            break;
        case DIKI_KEYDEF_END:
        case DIKI_NUMBER_OF_KEYS:
            // Not valid DirectFB codes, included here just for compeleteness
            return false;
        }
    }

    // Now set the modifiers
    dest.flags = left ? 0 : efLocationRight;
    if (src.modifiers & DIMM_SHIFT) {
        dest.flags |= efShiftDown;
    }
    if (src.modifiers & DIMM_CONTROL) {
        dest.flags |= efCtrlDown;
    }
    if (src.modifiers & (DIMM_ALT | DIMM_ALTGR | DIMM_META)) {
        dest.flags |= efAltDown;
    }
    if (src.modifiers & (DIMM_SUPER | DIMM_HYPER)) {
        dest.flags |= efCommandDown;
    }

    // Finally set the NME Event's code to the "symbol"
    dest.code = src.key_symbol;

    return true;
}
