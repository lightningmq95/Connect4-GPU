#include <iostream>
#include <vector>
#include <fstream>
#include <cuda_runtime.h>
#include <limits>
#include <climits>
#include <random>
#include <chrono>

#define ROWS 6
#define COLS 7

// prototype
__global__ void findBestMoveKernel(int* board, int player, int* scores, bool is_offensive);
__device__ int calculateBoardScore(int* board, int player);
void printBoard(int* board);
void logBoard(std::ofstream& logFile, int* board);
bool checkWin(int* board, int player);
bool isBoardFull(int* board);


// CUDA kernel to find the best move for a given player
__global__ void findBestMoveKernel(int* board, int player, int* scores, bool is_offensive) {
    int col = threadIdx.x;
    int opponent = (player == 1) ? 2 : 1;

    int temp_board[ROWS * COLS];
    for (int i = 0; i < ROWS * COLS; ++i) {
        temp_board[i] = board[i];
    }

    int row = -1;
    for (int r = ROWS - 1; r >= 0; --r) {
        if (temp_board[r * COLS + col] == 0) {
            row = r;
            break;
        }
    }

    if (row != -1) {
        // Simulate placing my piece
        temp_board[row * COLS + col] = player;
        int my_score = calculateBoardScore(temp_board, player);

        // Simulate opponent's best reply
        int opponent_best_reply_score = INT_MIN;
        for (int opp_col = 0; opp_col < COLS; ++opp_col) {
            int temp_board2[ROWS * COLS];
            for (int i = 0; i < ROWS * COLS; ++i) {
                temp_board2[i] = temp_board[i];
            }

            int opp_row = -1;
            for (int r = ROWS - 1; r >= 0; --r) {
                if (temp_board2[r * COLS + opp_col] == 0) {
                    opp_row = r;
                    break;
                }
            }

            if (opp_row != -1) {
                temp_board2[opp_row * COLS + opp_col] = opponent;
                int score = calculateBoardScore(temp_board2, opponent);
                if (score > opponent_best_reply_score) {
                    opponent_best_reply_score = score;
                }
            }
        }
        
        int final_score;
        if (is_offensive) {
            final_score = my_score * 2 - opponent_best_reply_score;
        } else {
            final_score = my_score - opponent_best_reply_score * 2;
        }
        scores[col] = final_score;

    } else {
        scores[col] = INT_MIN;
    }
}


// Device function to score a board state for a given player
__device__ int calculateBoardScore(int* board, int player) {
    int score = 0;
    int opponent = (player == 1) ? 2 : 1;

    // Score center column preference
    for (int r = 0; r < ROWS; ++r) {
        if (board[r * COLS + COLS / 2] == player) {
            score += 3;
        }
    }

    // Horizontal check
    for (int r = 0; r < ROWS; ++r) {
        for (int c = 0; c <= COLS - 4; ++c) {
            int p_count = 0, o_count = 0;
            for (int i = 0; i < 4; ++i) {
                if (board[r * COLS + c + i] == player) p_count++;
                else if (board[r * COLS + c + i] == opponent) o_count++;
            }
            if (p_count == 4) score += 10000;
            else if (p_count == 3 && o_count == 0) score += 100;
            else if (p_count == 2 && o_count == 0) score += 10;
        }
    }

    // Vertical check
    for (int c = 0; c < COLS; ++c) {
        for (int r = 0; r <= ROWS - 4; ++r) {
            int p_count = 0, o_count = 0;
            for (int i = 0; i < 4; ++i) {
                if (board[(r + i) * COLS + c] == player) p_count++;
                else if (board[(r + i) * COLS + c] == opponent) o_count++;
            }
            if (p_count == 4) score += 10000;
            else if (p_count == 3 && o_count == 0) score += 100;
            else if (p_count == 2 && o_count == 0) score += 10;
        }
    }

    // Positive diagonal check
    for (int r = 0; r <= ROWS - 4; ++r) {
        for (int c = 0; c <= COLS - 4; ++c) {
            int p_count = 0, o_count = 0;
            for (int i = 0; i < 4; ++i) {
                if (board[(r + i) * COLS + (c + i)] == player) p_count++;
                else if (board[(r + i) * COLS + (c + i)] == opponent) o_count++;
            }
            if (p_count == 4) score += 10000;
            else if (p_count == 3 && o_count == 0) score += 100;
            else if (p_count == 2 && o_count == 0) score += 10;
        }
    }

    // Negative diagonal check
    for (int r = 3; r < ROWS; ++r) {
        for (int c = 0; c <= COLS - 4; ++c) {
            int p_count = 0, o_count = 0;
            for (int i = 0; i < 4; ++i) {
                if (board[(r - i) * COLS + (c + i)] == player) p_count++;
                else if (board[(r - i) * COLS + (c + i)] == opponent) o_count++;
            }
            if (p_count == 4) score += 10000;
            else if (p_count == 3 && o_count == 0) score += 100;
            else if (p_count == 2 && o_count == 0) score += 10;
        }
    }
    return score;
}


void printBoard(int* board) {
    for (int r = 0; r < ROWS; ++r) {
        for (int c = 0; c < COLS; ++c) {
            char piece = '.';
            if (board[r * COLS + c] == 1) piece = 'X';
            else if (board[r * COLS + c] == 2) piece = 'O';
            std::cout << piece << " ";
        }
        std::cout << std::endl;
    }
    std::cout << "0 1 2 3 4 5 6" << std::endl;
}


void logBoard(std::ofstream& logFile, int* board) {
    for (int r = 0; r < ROWS; ++r) {
        for (int c = 0; c < COLS; ++c) {
            char piece = '.';
            if (board[r * COLS + c] == 1) piece = 'X';
            else if (board[r * COLS + c] == 2) piece = 'O';
            logFile << piece << " ";
        }
        logFile << std::endl;
    }
    logFile << "0 1 2 3 4 5 6" << std::endl;
    logFile << "-----------------" << std::endl;
}


bool checkWin(int* board, int player) {
    // Horizontal
    for (int r = 0; r < ROWS; ++r) {
        for (int c = 0; c <= COLS - 4; ++c) {
            if (board[r * COLS + c] == player && board[r * COLS + c + 1] == player && board[r * COLS + c + 2] == player && board[r * COLS + c + 3] == player) return true;
        }
    }
    // Vertical
    for (int c = 0; c < COLS; ++c) {
        for (int r = 0; r <= ROWS - 4; ++r) {
            if (board[r * COLS + c] == player && board[(r + 1) * COLS + c] == player && board[(r + 2) * COLS + c] == player && board[(r + 3) * COLS + c] == player) return true;
        }
    }
    // Positive diagonal
    for (int r = 0; r <= ROWS - 4; ++r) {
        for (int c = 0; c <= COLS - 4; ++c) {
            if (board[r * COLS + c] == player && board[(r + 1) * COLS + c + 1] == player && board[(r + 2) * COLS + c + 2] == player && board[(r + 3) * COLS + c + 3] == player) return true;
        }
    }
    // Negative diagonal
    for (int r = 3; r < ROWS; ++r) {
        for (int c = 0; c <= COLS - 4; ++c) {
            if (board[r * COLS + c] == player && board[(r - 1) * COLS + c + 1] == player && board[(r - 2) * COLS + c + 2] == player && board[(r - 3) * COLS + c + 3] == player) return true;
        }
    }
    return false;
}


bool isBoardFull(int* board) {
    for (int i = 0; i < COLS; ++i) {
        if (board[i] == 0) return false;
    }
    return true;
}

// game logic on the CPU
int main() {
    int* d_board;
    int* d_scores;
    char playAgain = 'y';

    // Allocate memory on the GPU once
    cudaMalloc(&d_board, ROWS * COLS * sizeof(int));
    cudaMalloc(&d_scores, COLS * sizeof(int));

    // --- NEW: Main loop to allow playing again ---
    while (playAgain == 'y' || playAgain == 'Y') {
        int h_board[ROWS * COLS] = {0}; // Reset host board for each new game

        // --- Setup for randomness ---
        unsigned seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
        std::mt19937 generator(seed);

        // --- Setup for logging (overwrites previous log) ---
        std::ofstream logFile("game_log.txt");
        if (!logFile.is_open()) {
            std::cerr << "Error: Could not open log file for writing." << std::endl;
            return 1;
        }
        logFile << "--- Connect 4 GPU Game Log ---" << std::endl;
        logBoard(logFile, h_board); // Log the initial empty board

        int turn = 0;
        // --- Inner game loop ---
        while (turn < ROWS * COLS) {
            int currentPlayer = (turn % 2) + 1;
            bool isOffensive = (currentPlayer == 1);

            std::cout << "\nTurn " << turn + 1 << ", Player " << (currentPlayer == 1 ? "X (Offensive)" : "O (Defensive)") << "'s move:" << std::endl;

            // Copy board from host to device
            cudaMemcpy(d_board, h_board, ROWS * COLS * sizeof(int), cudaMemcpyHostToDevice);

            // Launch kernel to find the best move
            findBestMoveKernel<<<1, COLS>>>(d_board, currentPlayer, d_scores, isOffensive);

            // Copy scores from device to host
            int h_scores[COLS];
            cudaMemcpy(h_scores, d_scores, COLS * sizeof(int), cudaMemcpyDeviceToHost);

            // Find the best move on the CPU
            int bestScore = std::numeric_limits<int>::min();
            for (int i = 0; i < COLS; ++i) {
                if (h_board[i] == 0) {
                    if (h_scores[i] > bestScore) {
                        bestScore = h_scores[i];
                    }
                }
            }

            // Randomly choose among the best moves
            std::vector<int> bestMoves;
            for (int i = 0; i < COLS; i++) {
                if (h_board[i] == 0 && h_scores[i] == bestScore) {
                    bestMoves.push_back(i);
                }
            }
            
            int bestMove = -1;
            if (!bestMoves.empty()) {
                std::uniform_int_distribution<int> distribution(0, bestMoves.size() - 1);
                bestMove = bestMoves[distribution(generator)];
            }

            // Make the move
            if (bestMove != -1) {
                for (int r = ROWS - 1; r >= 0; --r) {
                    if (h_board[r * COLS + bestMove] == 0) {
                        h_board[r * COLS + bestMove] = currentPlayer;
                        break;
                    }
                }
                logFile << "Turn " << turn + 1 << ": Player " << (currentPlayer == 1 ? 'X' : 'O') << " played in column " << bestMove << "." << std::endl;
                logBoard(logFile, h_board);
            }

            printBoard(h_board);

            // win check
            if (checkWin(h_board, currentPlayer)) {
                std::cout << "\nPlayer " << (currentPlayer == 1 ? "X (Offensive)" : "O (Defensive)") << " wins!" << std::endl;
                logFile << "\nPlayer " << (currentPlayer == 1 ? "X (Offensive)" : "O (Defensive)") << " wins!" << std::endl;
                break;
            }

            // draw check
            if (isBoardFull(h_board)) {
                std::cout << "\nIt's a draw!" << std::endl;
                logFile << "\nIt's a draw!" << std::endl;
                break;
            }

            turn++;
        }
        logFile.close();

        // play again
        std::cout << "\n--------------------------" << std::endl;
        std::cout << "Play again? (y/n): ";
        std::cin >> playAgain;
        std::cout << "--------------------------\n" << std::endl;
    }


    // Free GPU memory
    cudaFree(d_board);
    cudaFree(d_scores);
    
    std::cout << "Thanks for playing!" << std::endl;

    return 0;
}