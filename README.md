# Race Car Game — x86 Assembly (DOSBox)

A terminal-based race car game written in x86 assembly, built to run on DOSBox. No engines, no frameworks — just raw registers and interrupts.

## What it does
- Keyboard-controlled race car movement
- Custom keyboard interrupt handler (IRQ1)
- ESC to exit with a confirmation prompt + final score display
- Runs on real DOS / DOSBox

## How to run

1. Open DOSBox
2. Mount your project folder:
   ```
   mount c C:\path\to\project
   c:
   ```
3. Assemble and run:
   ```
   nasm RaceCarGame.asm -o RaceCarGame.com
   RaceCarGame.com
   ```

## Requirements
- [DOSBox](https://www.dosbox.com/)
- [NASM](https://www.nasm.us/) assembler

## Authors
- Minahil Basalat — 24L-3082
- Iman Abid — 24L-0707
