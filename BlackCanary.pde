/*  
 *  ------ Black Canary -------- 
 *  
 *  El  siguiente codigo esta diseñado para una waspmote V12 y
 *  una tarjeta para Gases Pro Board 1.0, cuatro sensores de gas, 
 *  un sensor de temperatura presion y humedad y un modulo WIFI 
 *  transportados en un dron para realizar monitoreo ambiental.
 * 
 *  La rutina se centra princpalmente en el ahorro de energia,  
 *  por este motivo, la tarjeta unicamente funciona cuando detecta
 *  vibraciones, tambien cuenta con un modo de ahorro de energia 
 *  y los sensores y modulos se encienden solo al ser usados y 
 *  se apagan al terminar su funcion. 
 *  
 *  La transmision de datos se realiza a traves de WIFI, sin 
 *  embargo los parametros para coneccion por xBEE estan comentados, 
 *  ya que se pretende dar soporte a esta tecnologia mas adelante.  
 *  
 *  
 *  Copyright (C) 2018 Centro Publico de Investigacion 
 *  e Innóvacion en Tecnologías de la información y Comunicacion 
 *  http://www.infotec.mx 
 *  
 *  This program is free software: you can redistribute it and/or modify 
 *  it under the terms of the GNU General Public License as published by  
 *  the Free Software Foundation, either version 3 of the License, or 
 *  (at your option) any later version. 
 *  
 *  This program is distributed in the hope that it will be useful, 
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *  GNU General Public License for more details. 
 *  
 *  You should have received a copy of the GNU General Public License 
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
 *  
 *  Version:           1.1
 *  Design:            Pedro Jesús Luna López
 *  Implementation:    Pedro Jesús Luna López
 *  ReleaseNotes:
 *    
 *  - ZigbeeSupport. 
 *  - low energy implemented  
 *  - File management corrected
 *  
 */

#define FDATAONSD 4094
#include <WaspStackEEPROM.h>
#include <WaspFrame.h>
#include <WaspXBee802.h>
#include <WaspSensorGas_Pro.h>

uint8_t firstTime=65000;
uint8_t rounds=65000;
uint8_t framesGen= 65000;
uint8_t batt=64999;

char* RX_ADDRESS= "0013A20040D7ED0F" ;
char* WASPMOTE_ID="BlackCanary";
uint8_t bEEPROM=99;
char toWrite[100];
uint8_t frameSD[100];

Gas CO(SOCKET_1);
Gas SO2(SOCKET_2);
Gas O3(SOCKET_3);
Gas NO2(SOCKET_4);
bmeGasesSensor  bme;
uint8_t socket=SOCKET0;

int writeonSD()
{
  if (bEEPROM)
    {
    switch (stack.pop(frame.buffer))
      {
        case 0:
        {
          USB.print ("Empty Frame... discarding  ");
          return 0;
          }
          break;
        case 1:
        {
          USB.print ("I/O Reading error :0  ");
          return 0;
          }
          break;
        case 2:
        {
          USB.print ("Error updating the new pointer :( ");
          return 0;
          }
          break;
        default:
          {
          USB.println ("Bytes read from EEPROM. Ready 2 send.  ");     
          }
        break; 
      }
     }
  SD.ON();
  SdFile file; 
  char* fileName = "Data.TXT";
  SD.openFile(fileName, &file, O_APPEND );
  memset(toWrite, 0x00, sizeof(toWrite) );
  Utils.hex2str( frame.buffer, toWrite, frame.length);
  SD.appendln(fileName, toWrite);
  SD.showFile(fileName);
  SD.closeFile(&file);     
  SD.OFF();
  if (!Utils.readEEPROM(FDATAONSD))
    {
      Utils.writeEEPROM(FDATAONSD,0x01);
    }
  return 1;
}


int storeInEEPROM()
{
   switch (stack.push(frame.buffer, frame.length))
    {
      case 0:
      {
        USB.print (F("Error writing on EEPROM :( saving on SD"));
        return 0;
        }
        break;      
      case 1:
      {
        USB.print (F("writting on EEPROM "));
        return 1;
        }
        break;
      case 2:
      {
        USB.print (F(" EEPROM full , swapping data to SD card "));
          return 0;
         }
        break;
      case 3:
      {
        USB.print (F("Block size Small try another size... "));
        return -1;
        }
        break;
      default:
        USB.println ("Hubo un error en la matrix :(  ");
        return -1;
        break; 
      }
  }


int send2Ground()
{
  xbee802.ON();
  xbee802.getChannel();
  xbee802.getPAN();
  xbee802.getEncryptionMode();
  frame.showFrame();

  int e=xbee802.send(RX_ADDRESS, frame.buffer, frame.length);
  if (0 == e)
    {
      USB.println(F("Message delivered"));
    }
    else 
    {
      USB.printf("Message sent, but not delivered Error: %d",e); 
      return 0 ;
    }
  xbee802.OFF();
  return 1;
}


int framesFromSensors(int part)
{
    frame.setFrameSize(90);
    frame.createFrame(BINARY, WASPMOTE_ID);
    framesGen++;
    switch (part)
      {
        case 1:
        {
          bme.ON();
          CO.ON();
          SO2.ON();
    
          frame.addSensor(SENSOR_GP_TC,   bme.getTemperature());
          frame.addSensor(SENSOR_GP_HUM, bme.getHumidity());
          frame.addSensor(SENSOR_GP_PRES, bme.getPressure());  
    
          frame.addSensor(SENSOR_GP_CO, CO.getConc());
          frame.addSensor(SENSOR_GP_TC, CO.getTemp());
          frame.addSensor(SENSOR_GP_HUM, CO.getHumidity());
          frame.addSensor(SENSOR_GP_PRES, CO.getPressure());  
    
          frame.addSensor(SENSOR_GP_SO2, SO2.getConc());
          frame.addSensor(SENSOR_GP_TC, SO2.getTemp());
          frame.addSensor(SENSOR_GP_HUM , SO2.getHumidity());
          frame.addSensor(SENSOR_GP_PRES, SO2.getPressure());  
  
          bme.OFF();
          CO.OFF();
          SO2.OFF();
  
        }
      break; 
      case 2:
        {
          O3.ON();
          NO2.ON();
   
          frame.addSensor(SENSOR_GP_O3, O3.getConc());
          frame.addSensor(SENSOR_GP_TC, O3.getTemp());
          frame.addSensor(SENSOR_GP_HUM, O3.getHumidity());
          frame.addSensor(SENSOR_GP_PRES, O3.getPressure());  

          frame.addSensor(SENSOR_GP_NO2, NO2.getConc());
          frame.addSensor(SENSOR_GP_TC, NO2.getTemp());
          frame.addSensor(SENSOR_GP_HUM, NO2.getHumidity());
          frame.addSensor(SENSOR_GP_PRES, NO2.getPressure());  

          O3.OFF();
          NO2.OFF();
       }
      break;
      default :
        {
          USB.println("nothing 2 DO");  
        }
      break;
      }
}



int framesFromFile()
{
  int8_t error=0;
  int8_t l=0;
  int8_t i=0;
  int32_t lines=0;
  SdFile file; 
  char* fileName = "Data.TXT";
  SdFile swapFile; 
  char* swapFileName = "Swap.TXT";
  USB.println("Frames From File");
  Utils.writeEEPROM(FDATAONSD,0x00);
  SD.ON();
  SD.openFile(fileName, &file, O_READ );
  lines=SD.numln(fileName);
  for (l=0; l<lines; l++)
  {
    SD.catln(fileName,l,1);      
    memset(frameSD, 0x00, sizeof(frameSD) ); 
    Utils.str2hex(SD.buffer, frameSD);
    frame.createFrame(BINARY, WASPMOTE_ID);
    frame.length=90;
    for (i=0;i<90; i++)
      {
        frame.buffer[i]=frameSD[i];
      }
    if (!send2Ground())
     {
      if (l==0)
       {
          USB.println("Still offline, appending data");
          SD.closeFile(&file); 
          SD.OFF();
          return 0;
       }
      error = 1;
      USB.println("connection failed");
      SD.create(swapFileName);
      SD.openFile(swapFileName, &swapFile, O_APPEND );
      SD.append(swapFileName, SD.buffer);
      SD.closeFile(&swapFile);
      if (!Utils.readEEPROM(FDATAONSD))
        {
        Utils.writeEEPROM(FDATAONSD,0x01);
        }  
    }
  }
  SD.closeFile(&file); 
  SD.del(fileName);
  SD.create(fileName);
  if(error)
    {
     USB.println("Swaping data");
     Utils.writeEEPROM(FDATAONSD,0x01);
     SD.openFile(fileName, &file, O_APPEND );
     SD.openFile(swapFileName, &swapFile, O_APPEND );
     lines=SD.numln(swapFileName);
     for(l=0; l<lines; l++)
       { 
        SD.catln( swapFileName, l, 1); 
        SD.append(fileName, SD.buffer);
       }
     SD.showFile(fileName);
     SD.closeFile(&file);
     SD.closeFile(&swapFile);     
     SD.del(swapFileName);
     SD.ls();
     SD.OFF();
     return 0;
   }
  SD.ls(); 
  SD.OFF();
  USB.println("Getting out clean ");
  return 1;
  }
 
int lo_batt_mode()
{
  
  USB.println("lo batt mode");
  for (int x=1; x<3;x++)
      {
        framesFromSensors(x);
        if (!storeInEEPROM())
        {
          bEEPROM=1;
          while (writeonSD())
            {
              USB.println(F("lines wrote on SD"));            
            }
          }
      }      
  if (!Utils.readEEPROM(FDATAONSD))
      {
        Utils.writeEEPROM(FDATAONSD,0x01);
      }
  USB.println(RTC.getTime()); 
  return 1;
}



int normal_mode()
{
    if (Utils.readEEPROM(FDATAONSD))
       {
        USB.println("Trying to reach the cloud");
        if (framesFromFile())
          {
            USB.println("success! data sincronized :D");
          }
          else 
          {
            for (int x=1; x<3;x++)
              {
                framesFromSensors(x);
                bEEPROM=0;    
                USB.println("Still offline... Saving on SD");
                writeonSD();
                
              }
            if (!Utils.readEEPROM(FDATAONSD))
                {
                  Utils.writeEEPROM(FDATAONSD,0x01);
                }  
          }
        }
    else
      {  
      for (int x=1; x<3;x++)
        {
        USB.println("Acquiring Data");
        framesFromSensors(x);
        //send2Ground();
        if (!send2Ground())
          {
          bEEPROM=0;    
          USB.println("Conection lost, going offline... Saving on SD");
            writeonSD();
            if (!Utils.readEEPROM(FDATAONSD))
            {
              Utils.writeEEPROM(FDATAONSD,0x01);
            }
          }
         }
        }
return 1;
}


void sensing ()
{
  
  if (batt< 15)
    {
      if (!lo_batt_mode())
        {
        USB.println(F("hola, soy una execpion de bateria baja"));//handle exeption 
        }
    }
    else
    { 
      if (!normal_mode())
        {
          USB.println(F("hola, soy una execpion en modo normal"));//handle exeption
        }
    }
}

void sleepOnLand()
{
ACC.ON(FS_8G);
ACC.setFF(300);
ACC.setIWU(300);
ACC.setSleepToWake();
USB.println(F("not fliying... sleeping...ZzzzZZZZzzz"));
PWR.sleep(ALL_OFF);
ACC.ON();  
ACC.unsetFF();
ACC.unsetIWU();
USB.ON();
RTC.ON();
SD.ON(); 
USB.println(F("move detected!  waking up :D"));
if (intFlag & ACC_INT)
  {
    sensing();
    }
clearIntFlag();
PWR.clearInterruptionPin();

}

void workingSchedule()
{
  if (RTC.hour>17||RTC.day>6||RTC.day<2)
  {
    USB.println(F("Out of workhours... goodbye..  "));
    PWR.hibernate("00:14:00:00", RTC_OFFSET, RTC_ALM1_MODE3);
   }
  }

/*
void initXbee()
{
  xbee802.ON();
  xbee802.setChannel( channel );
  if( xbee802.error_AT == 0 ) 
  {
    USB.print(F("1. Channel set OK to: 0x"));
    USB.printHex( xbee802.channel );
    USB.println();
  }
  else 
  {
    USB.println(F("1. Error calling 'setChannel()'"));
  }
  xbee802.setPAN( panID );
  // check the AT commmand execution flag
  if( xbee802.error_AT == 0 ) 
  {
    USB.print(F("2. PAN ID set OK to: 0x"));
    USB.printHex( xbee802.PAN_ID[0] ); 
    USB.printHex( xbee802.PAN_ID[1] ); 
    USB.println();
  }
  else 
  {
    USB.println(F("2. Error calling 'setPAN()'"));  
  }
  xbee802.setEncryptionMode( encryptionMode );
    if( xbee802.error_AT == 0 ) 
  {
    USB.print(F("3. AES encryption configured (1:enabled; 0:disabled):"));
    USB.println( xbee802.encryptMode, DEC );
  }
  else 
  {
    USB.println(F("3. Error calling 'setEncryptionMode()'"));
  }
  xbee802.setLinkKey( encryptionKey );
  if( xbee802.error_AT == 0 ) 
  {
    USB.println(F("4. AES encryption key set OK"));
  }
  else 
  {
    USB.println(F("4. Error calling 'setLinkKey()'")); 
  }
  xbee802.writeValues();
  if( xbee802.error_AT == 0 ) 
  {
    USB.println(F("5. Changes stored OK"));
  }
  else 
  {
    USB.println(F("5. Error calling 'writeValues()'"));   
  }
  USB.println(F("-------------------------------")); 
  }
*/
void setup()
{
  stack.initStack(FIFO_MODE);
  stack.initBlockSize(90);
  USB.print("stack ready 2 go \n");
  //  Utils.setLED(LED0, LED_OFF);
  //  Utils.setLED(LED1, LED_OFF);
  USB.ON();
  // initXbee();
  bme.ON();
  framesGen=0;
  rounds=0;
  batt=100;
  //put the right date&Time then Uncomment and upload to set RTC
  //RTC.setTime("18:06:25:02:20:29:00");
}





void loop()
{
if (rounds<=60000)
  {
   workingSchedule();
   batt=(uint8_t) PWR.getBatteryLevel();
   USB.println(RTC.getTime()); 
   USB.printf("%d o/o battery remain\n", batt);
  sleepOnLand();
  }
else 
  {
    USB.println(F("RERESHING SYSTEM WAIT PLEASE ..."));
    PWR.reboot(); 
  }

}
