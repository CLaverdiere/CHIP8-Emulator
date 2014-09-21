# Chip8 emulator main.

require_relative "src/chip8.rb"

def main()
  chip8 = CHIP8.new
  chip8.load_rom("games/PONG")

  until not chip8.program_running
    chip8.next_instruction()
  end
end

main()
