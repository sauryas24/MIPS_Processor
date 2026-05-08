> **Created as a part of the labs for the course CS220-Computer Organisation**

The Processor is a three cycle finite state machine, and performs the following operations in the states: <br>
>1. Fetches instructions, decodes them, and fethces appropriate memory from the Register File
>2. Executes ALU and system calls
>3. Writes to the Register File

It consists of a 128 Byte register file, and the Memory is implemented as an array of size 4 KB<br>
