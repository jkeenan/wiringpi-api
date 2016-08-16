package WiringPi::API;  

use strict;
use warnings;

our $VERSION = '1.02';

require XSLoader;
XSLoader::load('WiringPi::API', $VERSION);

require Exporter;
our @ISA = qw(Exporter);

my @wpi_c_functions = qw(
    wiringPiSetup wiringPiSetupSys wiringPiSetupGpio wiringPiSetupPhys
    pinMode pullUpDnControl digitalRead digitalWrite digitalWriteByte
    pwmWrite getAlt piBoardDev wpiToGpio physPinToGpio pwmSetRange lcdInit
    lcdHome lcdClear lcdDisplay lcdCursor lcdCursorBlink lcdSendCommand
    lcdPosition lcdCharDef lcdPutChar lcdPuts setInterrupt
);

my @wpi_perl_functions = qw(
    setup setup_sys setup_phys setup_gpio pin_mode pull_up_down read_pin
    write_pin pwm_write get_alt board_rev wpi_to_gpio phys_to_gpio 
    pwm_set_range lcd_init lcd_home lcd_clear lcd_display lcd_cursor
    lcd_cursor_blink lcd_send_cmd lcd_position lcd_char_def lcd_put_char
    lcd_puts set_interrupt
);

our @EXPORT_OK;

@EXPORT_OK = (@wpi_c_functions, @wpi_perl_functions);
our %EXPORT_TAGS;

$EXPORT_TAGS{wiringPi} = [@wpi_c_functions];
$EXPORT_TAGS{perl} = [@wpi_perl_functions];
$EXPORT_TAGS{all} = [@wpi_c_functions, @wpi_perl_functions];

# not yet implemented:
#extern void pinModeAlt          (int pin, int mode) ;
#extern int  analogRead          (int pin) ;
#extern void analogWrite         (int pin, int value) ;

sub new {
    return bless {}, shift;
}

# interrupt functions

sub set_interrupt {
    shift if @_ == 4;
    my ($pin, $edge, $callback) = @_;
    setInterrupt($pin, $edge, $callback);
}

# system functions

sub setup {
    return wiringPiSetup();
}
sub setup_sys {
    my $pin_map = RPi::WiringPi::Util::gpio_scheme('BCM');
    for (values %$pin_map){
        RPi::WiringPi::Util::export($_);
    }
    return wiringPiSetupSys();
}
sub setup_phys {
    return wiringPiSetupPhys();
}
sub setup_gpio {
    return wiringPiSetupGPIO();
}

# pin functions

sub pin_mode {
    shift if @_ == 3;
    my ($pin, $mode) = @_;
    pinMode($pin, $mode);
}
sub pull_up_down {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    # off, down up = 0, 1, 2
    pullUpDnControl($pin, $value);
}
sub read_pin {
    shift if @_ == 2;
    my $pin = shift;
    return digitalRead($pin);
}
sub write_pin {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    digitalWrite($pin, $value);
}
sub pwm_write {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    pwmWrite($pin, $value);
}
sub get_alt {
    shift if @_ == 2;
    my $pin = shift;
    return getAlt($pin);
}

# board functions

sub board_rev {
    return piBoardRev();
}
sub wpi_to_gpio {
    shift if @_ == 2;
    my $pin = shift;
    return wpiPinToGpio($pin);
}
sub phys_to_gpio {
    shift if @_ == 2;
    my $pin = shift;
    return physPinToGpio($pin);
}
sub phys_to_wpi {
    shift if @_ == 2;
    my $pin = shift;
    return physPinToWpi($pin);
}
sub pwm_set_range {
    shift if @_ == 2;
    my $range = shift;
    pwmSetRange($range);
}

# lcd functions

sub lcd_init {
    if (ref $_[0] =~ /RPi::WiringPi/ || $_[0] =~ /RPi::WiringPi/){
        shift;
    }
    my @args = @_;
    my $fd = lcdInit(@args); # LCD handle
    return $fd;
}
sub lcd_home {
    shift if @_ == 2;
    lcdHome($_[0]);
}
sub lcd_clear {
    shift if @_ == 2;
    lcdClear($_[0]);
}
sub lcd_display {
    shift if @_ == 3;
    my ($fd, $state) = @_;
    lcdDisplay($fd, $state);
}
sub lcd_cursor {
    shift if @_ == 3;
    my ($fd, $state) = @_;
    lcdCursor($fd, $state);
}
sub lcd_cursor_blink {
    shift if @_ == 3;
    my ($fd, $state) = @_;
    lcdCursorBlink($fd, $state);
}
sub lcd_send_cmd {
    shift if @_ == 3;
    my ($fd, $cmd) = @_;
    warn "\nlcdSendCommand() wiringPi function isn't documented!\n";
    lcdSendCommand($fd, $cmd);
}
sub lcd_position {
    shift if @_ == 4;
    my ($fd, $x, $y) = @_;
    lcdPosition($fd, $x, $y);
}
sub lcd_char_def {
    shift if @_ == 4;
    my ($fd, $index, $data) = @_;
    lcdCharDef($fd, $index, $data);
}
sub lcd_put_char {
    shift if @_ == 3;
    my ($fd, $data) = @_;
    lcdPutchar($fd, $data);
}
sub lcd_puts {
    shift if @_ == 3;
    my ($fd, $string) = @_;
    lcdPuts($fd, $string);
}

# threading functions

sub thread_create {
    my ($self, $sub_name) = @_;
    my $status = initThread($sub_name);

    print "thread failed to start\n" if $status != 0;
}
sub _vim{1;};

1;
__END__

=head1 NAME

WiringPi::API - Direct access to Raspberry Pi's wiringPi API, with optional
Perl OO access

=head1 SYNOPSIS

    # import the API functions directly

    use WiringPi::API qw(:wiringPi)

    # import the Perl wrapped functions

    use WiringPi::API qw(:perl)

    # import both versions

    use WiringPi::API qw(:all)

    # use as a base class with OO functionality

    use parent 'WiringPi::API';

    # use in the traditional Perl OO way

    use WiringPi::API;

    my $api = WiringPi::API->new;

    # !!!
    # regardless of using OO or functional style, one of the C<setup*()>
    # functions MUST be called prior to doing anything

    $api->setup;

=head1 DESCRIPTION

This is an XS-based module, and requires L<wiringPi|http://wiringpi.com> to be
installed. The C<wiringPiDev> shared library is also required (for the LCD
functionality), but it's installed by default with C<wiringPi>.

This module allows you to import the wiringPi's functions directly as-is, use
it as a Perl base class, export the Perl wrapped functions, or use it in a
traditional Perl OO way.

See the documentation on the L<wiringPi|http://wiringpi.com> website for a more
in-depth description of most of the functions it provides. Some of the
functions we've wrapped are not documented, they were just selectively plucked
from the C code itself.

=head1 EXPORT_OK

Exported with the C<:wiringPi> tag, these XS functions map directly to the
wiringPi functions with their original names. Note that C<setInterrupt> is not
a direct wrapper, it's a custom C wrapper for C<wiringPiISR()> in order to
make it functional here.

    wiringPiSetup wiringPiSetupSys wiringPiSetupGpio wiringPiSetupPhys
    pinMode pullUpDnControl digitalRead digitalWrite digitalWriteByte
    pwmWrite getAlt piBoardDev wpiToGpio physPinToGpio pwmSetRange lcdInit
    lcdHome lcdClear lcdDisplay lcdCursor lcdCursorBlink lcdSendCommand
    lcdPosition lcdCharDef lcdPutChar lcdPuts setInterrupt

Exported with the C<:perl> tag. Perl wrapper functions for the XS functions.

    setup setup_sys setup_phys setup_gpio pin_mode pull_up_down read_pin
    write_pin pwm_write get_alt board_rev wpi_to_gpio phys_to_gpio 
    pwm_set_range lcd_init lcd_home lcd_clear lcd_display lcd_cursor
    lcd_cursor_blink lcd_send_cmd lcd_position lcd_char_def lcd_put_char
    lcd_puts set_interrupt

=head1 EXPORT_TAGS

=head2 :wiringPi

See L<EXPORT_OK>

=head2 :perl

See L<EXPORT_OK>

=head2 :all

Exports all available exportable functions.

=head1 CORE METHODS

=head2 new()

NOTE: After an object is created, one of the C<setup*> methods must be called
to initialize the Pi board.

Returns a new C<WiringPi::API> object.

=head2 setup()

Maps to C<int wiringPiSetup()>

Sets the pin numbering scheme to C<WPI> (wiringPi numbers).

See L<wiringPi setup functions|http://wiringpi.com/reference/setup> for
for information on this method.

Note that only one of the C<setup*()> methods can be called per program run.

=head2 setup_sys()

Maps to C<int wiringPiSetupSys()>

Sets the pin numbering scheme to C<BCM> (Broadcom numbers).

See L<wiringPi setup functions|http://wiringpi.com/reference/setup> for
for information on this method.

Note that only one of the C<setup*()> methods can be called per program run.

=head2 setup_phys()

Maps to C<int wiringPiSetupPhys()>

Sets the pin numbering scheme to C<PHYS> (physical board numbers).

See L<wiringPi setup functions|http://wiringpi.com/reference/setup> for
for information on this method.

Note that only one of the C<setup*()> methods can be called per program run.

=head2 setup_gpio()

Maps to C<int wiringPiSetupGpio()>

Sets the pin numbering scheme to C<BCM> (Broadcom numbers).

See L<wiringPi setup functions|http://wiringpi.com/reference/setup> for
for information on this method.

Note that only one of the C<setup*()> methods can be called per program run.

=head2 pin_mode($pin, $mode)

Maps to C<void pinMode(int pin, int mode)>

Puts the GPIO pin in either INPUT or OUTPUT mode.

Parameters:

    $pin

Mandatory: The GPIO pin number, using your currently in-use numbering scheme
(C<BCM> aka GPIO by default).

    $mode

Mandatory: C<0> for INPUT, C<1> OUTPUT, C<2> PWM_OUTPUT and C<3> GPIO_CLOCK.

=head2 read_pin($pin);

Maps to C<int digitalRead(int pin)>

Returns the current state (HIGH/on, LOW/off) of a given pin.

Parameters:
    
    $pin

Mandatory: The GPIO pin number, using your currently in-use numbering scheme
(C<BCM> aka GPIO by default).

=head2 write_pin($pin, $state)

Maps to C<void digitalWrite(int pin)>

Sets the state (HIGH/on, LOW/off) of a given pin.

Parameters:

    $pin

Mandatory: The GPIO pin number, using your currently in-use numbering scheme
(C<BCM> aka GPIO by default).

    $state

Mandatory: C<1> to turn the pin on (HIGH), and C<0> to turn it LOW (off).

=head2 pull_up_down($pin, $direction)

Maps to C<void pullUpDnControl(int pin, int pud)>

Enable/disable the built-in pull up/down resistors for a specified pin.

Parameters:

    $pin

Mandatory: The GPIO pin number, using your currently in-use numbering scheme
(C<BCM> aka GPIO by default).

    $direction

Mandatory: C<2> for UP, C<1> for DOWN and C<0> to disable the resistor.

=head2 pwm_write($pin, $value)

Maps to C<void pwmWrite(int pin, int value)>

Sets the Pulse Width Modulation duty cycle (on-time) of the pin.

Parameters:

    $pin

Mandatory: The GPIO pin number, using your currently in-use numbering scheme
(C<BCM> aka GPIO by default).

    $value

Mandatory: C<0> to C<1023>. C<0> is 0% (off) and C<1023> is 100% (fully on).

=head2 get_alt($pin)

Maps to C<int getAlt(int pin)>

This returns the current mode of the pin (using C<getAlt()> C call). Modes are
INPUT C<0>, OUTPUT C<1>, PWM C<2> and CLOCK C<3>.

Parameters:
    
    $pin

Mandatory: The GPIO pin number, using your currently in-use numbering scheme
(C<BCM> aka GPIO by default).

=head1 BOARD METHODS

=head2 board_rev()

Maps to C<int piBoardRev()>

Returns the Raspberry Pi board's revision.

=head2 wpi_to_gpio($pin_num)

Maps to C<int wpiPinToGpio(int pin)>

Converts a C<wiringPi> pin number to the Broadcom (BCM) representation, and
returns it.

Parameters:

    $pin_num

Mandatory: The GPIO pin number, using your currently in-use numbering scheme
(C<BCM> aka GPIO by default).

=head2 phys_to_gpio($pin_num)

Maps to C<int physPinToGpio(int pin)>

Converts the pin number on the physical board to the Broadcom (BCM)
representation, and returns it.

Parameters:

    $pin_num

Mandatory: The pin number on the physical Raspberry Pi board.

=head2 phys_to_wpi($pin_num)

Maps to C<int physPinToWpi(int pin)>

Converts the pin number on the physical board to the C<wiringPi> numbering
representation, and returns it.

Parameters:

    $pin_num

Mandatory: The pin number on the physical Raspberry Pi board.

=head2 pwm_set_range($range);

Maps to C<void pwmSetRange(int range)>

Sets the range register of the Pulse Width Modulation (PWM) functionality. It
defaults to C<1024> (C<0-1023>).

Parameters:

    $range

Mandatory: An integer between C<0> and C<1023>.

=head1 LCD METHODS

There are several methods to drive standard Liquid Crystal Displays. See
L<wiringPiDev LCD page|http://wiringpi.com/dev-lib/lcd-library/> for full
details.

=head2 lcd_init(%args)

Maps to:

    int lcdInit(
        rows, cols, bits, rs, strb,
        d0, d1, d2, d3, d4, d5, d6, d7
    );

Initializes the LCD library, and returns an integer representing the handle
handle (file descriptor) of the device. The return is supposed to be constant,
so DON'T change it.

Parameters:

    %args = (
        rows => $num,       # number of rows. eg: 16 or 20
        cols => $num,       # number of columns. eg: 2 or 4
        bits => 4|8,        # width of the interface (4 or 8)
        rs => $pin_num,     # pin number of the LCD's RS pin
        strb => $pin_num,   # pin number of the LCD's strobe (E) pin
        d0 => $pin_num,     # pin number for LCD data pin 1
        ...
        d7 => $pin_num,     # pin number for LCD data pin 8
    );

Mandatory: All entries must have a value. If you're only using four (4) bit
width, C<d4> through C<d7> must be set to C<0>.

Note: When in 4-bit mode, the C<d0> through C<3> parameters actually map to
pins C<d4> through C<d7> on the LCD board, so you need to connect those pins
to their respective selected GPIO pins.

=head2 lcd_home($fd)

Maps to C<void lcdHome(int fd)>

Moves the LCD cursor to the home position (top row, leftmost column).

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

=head2 lcd_clear($fd)

Maps to C<void lcdClear(int fd)>

Clears the LCD display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

=head2 lcd_display($fd, $state)

Maps to C<void lcdDisplay(int fd, int state)>

Turns the LCD display on and off.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $state

Mandatory: C<0> to turn the display off, and C<1> for on.

=head2 lcd_cursor($fd, $state)

Maps to C<void lcdCursor(int fd, int state)>

Turns the LCD cursor on and off.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.=head2 lcd_clear($fd)

    $state

Mandatory: C<0> to turn the cursor off, C<1> for on.

=head2 lcd_cursor_blink($fd, $state)

Maps to C<void lcdCursorBlink(int fd, int state)>

Allows you to enable/disable a blinking cursor.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.=head2 lcd_clear($fd)

    $state

Mandatory: C<0> to stop blinking, C<1> to enable.

=head2 lcd_send_cmd($fd, $command)

Maps to C<void lcdSendCommand(int fd, char command)>

Sends any arbitrary command to the LCD.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.=head2 lcd_clear($fd)

    $command

Mandatory: A command to submit to the LCD.

=head2 lcd_position($fd, $x, $y)

Maps to C<void lcdPosition(int fd, int x, int y)>

Moves the cursor to the specified position on the LCD display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $x

Mandatory: Column position. C<0> is the left-most edge.

    $y

Mandatory: Row position. C<0> is the top row.

=head2 lcd_char_def($fd, $index, $data)

Maps to C<void lcdCharDef(int fd, unsigned char data [8])>

This allows you to re-define one of the 8 user-definable characters in the
display. The data array is 8 bytes which represent the character from the
top-line to the bottom line. Note that the characters are actually 5×8, so
only the lower 5 bits are used. The index is from 0 to 7 and you can
subsequently print the character defined using the lcdPutchar() call.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $index

Mandatory: Index of the display character. Values are C<0-7>.

    $data

Mandatory: See above description.

=head2 lcd_put_char($fd, $char)

Maps to C<void lcdPutChar(int fd, unsigned char data)>

Writes a single ASCII character to the LCD display, at the current cursor
position.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $char

Mandatory: A single ASCII character.

=head2 lcd_puts($fd, $string)

Maps to C<void lcdPuts(int fd, char *string)>

Writes a string to the LCD display, at the current cursor position.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $string

Mandatory: A string to display.

=head1 INTERRUPT METHODS

=head2 set_interrupt($pin, $edge, $callback)

IMPORTANT: The interrupt functionality requires that your Perl can be used
in pthreads. If you do not have a threaded Perl, the program will cause a
segmentation fault.

Wrapper around wiringPi's C<wiringPiISR()> that allows you to send in the name
of a Perl sub in your own code that will be called if an interrupt is
triggered.

Parameters:

    $pin

Mandatory: The pin number to set the interrupt for. Must be in C<BCM> numbering
scheme.

    $edge

Mandatory: C<1> (lowering), C<2> (raising) or C<3> (both).

    $callback

Mandatory: The string name of a subroutine previously written in your user code
that will be called when the interrupt is triggered. This is your interrupt
handler.

head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
