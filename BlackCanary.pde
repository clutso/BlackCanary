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
 *  Version:           1.0
 *  Design:            Pedro Jesús Luna López
 *  Implementation:    Pedro Jesús Luna López
 *  ReleaseNotes:
 *    
 *  - First version ever (use at your own risk). 
 *  - A lot of features to optimize  
 *  - Tons of bugs detected
 *  
 */

#include <WaspStackEEPROM.h>
#include <WaspFrame.h>
//#include <WaspXBee802.h>
#include <WaspSensorGas_Pro.h>
#include <WaspWIFI.h>

int firstTime=65000;
int rounds=65000;
int framesGen= 65000;
int batt=64999;
//char* RX_ADDRESS= "0013A20040D7ED0F" ;
//uint8_t  panID[2] = {0x33,0x32}; 
//uint8_t  channel = 0x0B;
//uint8_t encryptionMode = 1;
//char*  encryptionKey= "WaspmoteLinkKey!"; 
char* WASPMOTE_ID="BlackCanary";

///uint8_t dataONSD=0;

Gas CO(SOCKET_1);
Gas SO2(SOCKET_2);
Gas O3(SOCKET_3);
Gas NO2(SOCKET_4);
bmeGasesSensor  bme;
uint8_t socket=SOCKET0;

void writeonSD()
{
  switch (stack.pop(frame.buffer))
    {
      case 0:
      {
        USB.print ("Empty Frame... discarding  ");
        }
        break;
      
      case 1:
      {
        USB.print ("I/O Reading error :0  ");
        }
        break;
        
      case 2:
      {
        USB.print ("Error updating the new pointer :( ");
        }
        break;
        
      default:
        USB.println ("Bytes read from EEPROM. Ready 2 send.  ");
        break; 
      }
      SD.ON();
      SdFile file; 
      const char* fileName = "Data.TXT";
 //     SD.create(fileName);
      SD.openFile(fileName, &file, O_APPEND );
      SD.ls();
      for( int i= 0; i < frame.length ; i++ )
        {   
          char temp=(char)frame.buffer[i];
          SD.append(fileName, &temp);
         }
      SD.appendln(fileName, "");
      SD.closeFile(&file);     
      SD.OFF();

        Utils.writeEEPROM(4094,0x01);
      //dataONSD=1;
}

void storeInEEPROM()
{
   switch (stack.push(frame.buffer, frame.length))
    {
      case 0:
      {
        USB.print ("Error writing on EEPROM :( saving on SD");
        writeonSD();
        }
        break;
      
      case 1:
      {
        USB.print ("writting on EEPROM ");
        }
        break;
        
      case 2:
      {
        USB.print (" EEPROM full , swapping data to SD card ");
        
          for (int x=0;x<10; x++)
          {          
          writeonSD();
          }
        }
        break;
        
      case 3:
      {
        USB.print ("Block size Small try another size... ");
        }
        break;
      default:
        USB.println ("Hubo un error en la matrix :(  ");
        break; 
      }
  }

int send2Ground()
{
WIFI.ON(socket);
WIFI.join("meshlium");
     if ( WIFI.sendHTTPframe(IP,"10.10.10.1", 80, frame.buffer, frame.length))
        {
       USB.printf("\n\nconnection succeed\n");
        //USB.println(WIFI.answer);
        USB.printf("\n\n\n");
        delay (2000);
        WIFI.OFF();
        return 1; 
        }
 
    else
      {

          USB.println("connection failed :( Writting  on EEPROM"); 
          delay (2000);
          WIFI.OFF();
          return 0;
        }
  /*
  xbee802.getChannel();
  USB.print(F("channel: "));
  USB.printHex(xbee802.channel);
  USB.println();

  xbee802.getPAN();
  USB.print(F("panid: "));
  USB.printHex(xbee802.PAN_ID[0]); 
  USB.printHex(xbee802.PAN_ID[1]); 
  USB.println(); 

  xbee802.getEncryptionMode();
  USB.print(F("encryption mode: "));
  USB.printHex(xbee802.encryptMode);
  USB.println(); 

  USB.println(F("-------------------------------")); 
  
  if (0 == xbee802.send(RX_ADDRESS, frame.buffer, frame.length))
  {
    USB.println(F("Message delivered"));
    }
    else 
    {
    USB.println(F("Message sent, but not delivered ")); 
    }
//  xbee802.OFF();
  */
  return 0;
}

int lo_batt_mode()
{
     return 0; 
}

void initXbee()
{
  /*
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

  */
  }

int framesFromSensors(int part)
{
  switch (part)
  {
  case 1:
  {
  CO.ON();
  SO2.ON();
  bme.ON();
  O3.ON();
  frame.createFrame(ASCII, WASPMOTE_ID);
  framesGen++;

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

  frame.addSensor(SENSOR_GP_O3, O3.getConc());
  frame.addSensor(SENSOR_GP_TC, O3.getTemp());
  frame.addSensor(SENSOR_GP_HUM, O3.getHumidity());
  frame.addSensor(SENSOR_GP_PRES, O3.getPressure());  

  frame.showFrame();
  bme.OFF();
  CO.OFF();
  SO2.OFF();
  O3.OFF();
  }
  break; 
  case 2:
  {
  NO2.ON();
  frame.createFrame(ASCII, WASPMOTE_ID);
  framesGen++;

  frame.addSensor(SENSOR_GP_NO2, NO2.getConc());
  frame.addSensor(SENSOR_GP_TC, NO2.getTemp());
  frame.addSensor(SENSOR_GP_HUM, NO2.getHumidity());
  frame.addSensor(SENSOR_GP_PRES, NO2.getPressure());  
  frame.showFrame();
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
      SD.ON();
      SdFile file; 
      const char* fileName = "Data.TXT";
      SD.openFile(fileName, &file, O_RDWR );
      int l=0;
      int i=0;
      int32_t lines=SD.numln(fileName);
      SD.cat(fileName,0, 255);
      USB.printf("This file has %d lines.. enjoy...\n", lines);
      frame.createFrame(ASCII, WASPMOTE_ID);
      frame.length=255;
      while(l<lines)
        {
         if ((i>0)&&(SD.buffer[i-1]==0x0d && SD.buffer[i]==0x0a))
         {
          l++;
            frame.length=i;
            SD.cat(fileName, frame.length+1, 255);
            i=0;
            USB.printf("Finnishing process of line: %d\n", l);                
            send2Ground();
            frame.createFrame(ASCII, WASPMOTE_ID);
            frame.length=255;
         }
         else 
         {
          frame.buffer[i] = SD.buffer[i];
           USB.printf("%c", frame.buffer[i]);
          }
          i++;
         }
         
      SD.closeFile(&file); 
      SD.del(fileName);    
      SD.create(fileName);
      SD.ls(); 
      SD.OFF();
    Utils.writeEEPROM(4094,0x0); //camiar a 0
}

int normal_mode()
{
  if (Utils.readEEPROM(4094))
    {
    framesFromFile();
    return 0;
    }
  else 
    {
    for (int x=1; x<3;x++)
      {
        framesFromSensors(x);
        if (send2Ground())
        {
          (" packet %d sent",x);
          //return 0;
        }
        else 
          {
            storeInEEPROM();
  //      return 0;
          }      

        }
      return 0;        
    }  
USB.println(RTC.getTime()); 
return 1;
}







void sensing ()
{
  if (batt< 15)
    {
      if (lo_batt_mode())
        {
        USB.println(F("hola, soy una execpion de bateria baja"));//handle exeption 
        }
    }
    else
    { 
      if (normal_mode())
        {
          USB.println(F("hola, soy una execpion en modo normal"));//handle exeption
        }
    }
 USB.println(freeMemory());
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
    USB.println(F("Going 2 sleep"));
    PWR.hibernate("00:14:00:00", RTC_OFFSET, RTC_ALM1_MODE3);
   }
  }

void initWifi()
{
/*
  USB.println("trying wifi"); 
  WIFI.setDHCPoptions(DHCP_ON);
  USB.println("Working with dhcp"); 
  WIFI.setESSID("meshlium");
  USB.println("conecting to meshlium");
  WIFI.setConnectionOptions(HTTP|CLIENT_SERVER);
  WIFI.setAutojoinAuth(OPEN);
  WIFI.setJoinMode(AUTO_STOR);
  WIFI.setJoinMode(MANUAL);
  WIFI.storeData();
  USB.println("Data Saved"); 
  */
  WIFI.ON(SOCKET0);
  USB.println("trying connection"); 
  WIFI.join("meshlium");
  if(WIFI.isConnected(5000)==true)
  {
      USB.println("connection succed"); 
      }
  else{
          USB.println("connection failed :("); 
    }
  
  WIFI.OFF();
  }

void setup()
{
  stack.initStack(FIFO_MODE);
  stack.initBlockSize(255);
  USB.print("stack ready 2 go ");
//  Utils.setLED(LED0, LED_OFF);
//  Utils.setLED(LED1, LED_OFF);
  USB.ON();
  initWifi();
  //frame.setFrameSize(XBEE_802_15_4, UNICAST_16B,ENABLED, ENABLED );
//  initXbee();
  
  bme.ON();
  frame.setFrameSize(255);
  frame.setID(WASPMOTE_ID);
  framesGen=0;
  rounds=0;
  batt=100;
//put the right date&Time then Uncomment and upload to set RTC
//RTC.setTime("18:05:24:05:17:28:00");
}

void loop()
{
if (rounds<=60000)
  {
   workingSchedule();
   batt=(uint8_t) PWR.getBatteryLevel();
   USB.printf("%d o/o battery remain\n", batt);
   sleepOnLand();
   //sensing();
  }
else 
  {
    USB.println(F("RERESHING SYSTEM WAIT PLEASE ..."));
    PWR.reboot(); 
  }
}



