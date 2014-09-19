require_relative "src/chip8.rb"

def main()
  chip8 = CHIP8.new
  puts chip8.get_opcode_desc(0xf166)
end

main()
