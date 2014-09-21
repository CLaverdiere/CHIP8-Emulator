require_relative "src/chip8.rb"

def main()
  chip8 = CHIP8.new
  puts chip8.do_instruction(0x854e)
end

main()
