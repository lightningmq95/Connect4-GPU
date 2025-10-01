# Compiler
NVCC = nvcc

# Detect OS
ifeq ($(OS),Windows_NT)
	TARGET = connect4.exe
	RM = del /Q
else
	TARGET = connect4
	RM = rm -f
endif

# Flags
NVCC_FLAGS = -arch=sm_75

# Source
SOURCE = main.cu

all: clean $(TARGET)

$(TARGET): $(SOURCE)
	$(NVCC) $(NVCC_FLAGS) $(SOURCE) -o $(TARGET)
	@echo "Compilation successful! Run the game with: $(TARGET)"

clean:
	-$(RM) $(TARGET)
	@echo "Cleaned up project files."