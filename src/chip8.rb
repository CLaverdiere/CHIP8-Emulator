class CHIP8
  attr_reader :display, :memory, :registers, :stack, :timers

  def initialize()
    @display = [[0b0] * 0x40] * 0x20
    @memory = [0x00] * 0x1000
    @registers = [0x00] * 0x10
    @stack = [0x00] * 0x40
    @timers = {delay: 0x40, sound: 0x40}
  end


end
