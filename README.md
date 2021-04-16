# CSC258-Computer-Organization

This is all my labs and assignments from CSC258H1 S 20211:Computer Organization I took at the University of Toronto.

## Course Description
Computer structures, machine languages, instruction execution, addressing techniques, and digital representation of data. Computer system organization, memory storage devices, and microprogramming. Block diagram circuit realizations of memory, control and arithmetic functions. There are a number of laboratory periods in which students conduct experiments with digital logic circuits.

## Labs - Logism


## Assembly Final Project: Centipede
#### Overview
In this project, we will implement a modified version of the popular 1980 Atari game Centipede using MIPS assembly. Familiarize yourself with the game here (https://www.youtube.com/watch?v=V7XEmf02zEM) or here (Flash required; https://my.ign.com/atari/centipede).
Since we don't have access to physical computers with MIPS processors, we will test our implementation in a simulated environment within MARS, i.e., a simulated bitmap display and a simulated keyboard input.

#### Getting Started
1. If you haven’t downloaded it already, get MARS v4.5 [here](https://courses.missouristate.edu/KenVollmar/MARS/download.htm).
2. Open a new file called centipede.s in MARS
3. Set up display: Tools > Bitmap display
 + Set parameters 
    + unit width & height to 8
    + Display Width & height in Pixels to 256
    + base address for display to 0x10008000($bg)
    + Click “Connect to MIPS” once these are set.
4. Set up keyboard: Tools > Keyboard and Display MMIO Simulator
○ Click “Connect to MIPS”
...and then, to run your program:
5. Run > Assemble (see the memory addresses and values, check for bugs)
6. Run > Go (to start the run)
7. Input the character j or k or x in Keyboard area (bottom white box) in Keyboard
and Display MMIO Simulator window
