#include <KeyCodes.h>


namespace lime
{

int TranslateASCIICodeToKeyCode(int asciiCode)
{
   // Map lowercase letters to uppercase equivalent
   // ASCII codes for uppercase letters match their keycodes
   if (asciiCode >= 97 && asciiCode <= 122)
   {
      asciiCode -= 32;
   }
   
   switch (asciiCode)
   {
      /* 0-31 are control codes */
      case 10:   return keyENTER;
      case 13:   return keyENTER;
      /* 32 is a space, maps to self */
      case 33:   return keyNUMBER_1;
      case 34:   return keyQUOTE;
      case 35:   return keyNUMBER_3;
      case 36:   return keyNUMBER_4;
      case 37:   return keyNUMBER_5;
      case 38:   return keyNUMBER_7;
      case 39:   return keyQUOTE;
      case 40:   return keyNUMBER_9;
      case 41:   return keyNUMBER_0;
      case 42:   return keyNUMBER_2;
      case 43:   return keyEQUAL;
      case 44:   return keyCOMMA;   
      case 45:   return keyMINUS;   
      case 46:   return keyPERIOD;
      case 47:   return keySLASH;
      /* 48-57 are digits, map to self */
      case 58:   return keySEMICOLON;
      case 59:   return keySEMICOLON;
      case 60:   return keyCOMMA;
      case 61:   return keyEQUAL;
      case 62:   return keyPERIOD;
      case 63:   return keySLASH;
      case 64:   return keyNUMBER_2;
      /* 65-90 are uppercase letters, map to self */      
      case 91:   return keyLEFTBRACKET;
      case 92:   return keyBACKSLASH;
      case 93:   return keyRIGHTBRACKET;
      case 94:   return keyNUMBER_6;
      case 95:   return keyMINUS;
      case 96:   return keyBACKQUOTE;
      /* 97-122 are lowercase letters, handled above */
      case 123:  return keyLEFTBRACKET;
      case 124:  return keyBACKSLASH;
      case 125:  return keyRIGHTBRACKET;
      case 126:  return keyBACKQUOTE;
      default:   return asciiCode;
   }
}

}


