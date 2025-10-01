# Competing GPUs: Connect 4

This project is an implementation of a Connect 4 game where two simulated GPUs compete against each other. It's designed to fulfill the requirements of the "Competing GPUs" peer-graded assignment.

The game runs in the command line and demonstrates two different AI strategies implemented in CUDA C++.

## Project Overview

The core of this project is a C++/CUDA application that simulates a game of Connect 4. The two players are both controlled by the GPU, but they use different strategies to decide their moves.

- **GPU Player 1 (X): Offensive Strategy.** This player's primary goal is to create its own winning lines. It heavily favors moves that create three-in-a-row or other strong offensive positions.

- **GPU Player 2 (O): Defensive Strategy.** This player's primary goal is to block the opponent. It heavily favors moves that prevent Player 1 from getting four-in-a-row.

The game state is managed on the CPU (host), but the decision-making for each move is offloaded to the GPU (device).

## Generating a Game Log for Presentation

To help with the "replay" and demonstration part of the assignment, the program automatically generates a `game_log.txt` file in the same directory.

This file now records both the move description and a full visual of the board after every turn, making it perfect for creating presentation slides. **Note:** The log file is overwritten with the details of the most recently played game each time you start a new match.

Example `game_log.txt` output:

```
--- Connect 4 GPU Game Log ---
Turn 1: Player X played in column 3.
. . . . . .
. . . . . .
. . . . . .
. . . . . .
. . . . . .
. . . X . .
0 1 2 3 4 5 6

---

Turn 2: Player O played in column 3.
. . . . . .
. . . . . .
. . . . . .
. . . . . .
. . . O . .
. . . X . .
0 1 2 3 4 5 6

---
```

## Prerequisites

To compile and run this project, you need:

- An NVIDIA GPU.
- The NVIDIA CUDA Toolkit installed. This provides the `nvcc` compiler.
- A compatible environment (Windows, macOS, or Linux).

## How to Compile and Run

Use the provided `Makefile` for the easiest compilation.

1.  Open your terminal or PowerShell and navigate to the directory where you saved `main.cu` and `Makefile`.
2.  Compile the code by running the `make` command:
    ```bash
    make
    ```
3.  Run the game from your terminal:
    - On Windows: `.\connect4.exe`
    - On Linux/macOS: `./connect4`

The game will play out in your terminal. After a match is complete, you will be prompted if you want to play again. Enter 'y' to start a new game or 'n' to exit.
