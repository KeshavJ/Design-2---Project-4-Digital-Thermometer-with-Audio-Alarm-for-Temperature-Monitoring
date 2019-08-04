# Design-2---Project-4-Digital-Thermometer-with-Audio-Alarm-for-Temperature-Monitoring

The objective of this project is to build a digital thermometer which measures the ambient
temperature, allows the user to set and adjust a threshold value and sounds an alarm if this
threshold value is exceeded. This system uses a PIC16F690 microcontroller and a LM35 temperature sensor that will measure the
ambient temperature in the range of 0°C to 99°C and display the ambient temperature on a 2 digit,
seven segment display. The temperature measurement must be instantaneous and continuous.
The system must have two multi-functional buttons to select the system functional mode and adjust
the threshold temperature. 

The system will have two modes:
- “run” which continuously displays the current temperature.
- “Set threshold” which allows the user to set the threshold temperature level.

In order to set the threshold, the user should press and hold either of the buttons. After 2 seconds
the device will enter the “Set threshold” mode. If the switch is released before 2 seconds, the 2
second cycle restarts over the next time the switch is pressed. The “Set threshold” mode will be
indicated by flashing the display on and off. The value that is displayed will be the current threshold
temperature set point.

In the “Set threshold” mode, the buttons are used to adjust the threshold temperature level. One
button is used to decrement the threshold temperature by 1°C and the other button to increment
the threshold temperature by 1°C. If neither button is pressed for 3 seconds, the device will return
to the normal “run” mode and display the current temperature and the display will stop flashing.
The set threshold temperature value should be retained and later displayed in the appropriate mode
even after the system is powered down and up.

If the threshold value is exceeded an audio alarm will sound.
