//========================================================================
// chip_code_test
//========================================================================

`default_nettype none
`timescale 1 ns / 1 ps
`include "uart_print.v"

//========================================================================
// Top-Level Test Harness
//========================================================================

module chip_code_test_tb;

  //----------------------------------------------------------------------
  // Create clocks
  //----------------------------------------------------------------------

  // Clock for Caravel

  reg clock = 1'b0;
  always #12.5 clock = ~clock;

  // User clock

  reg clk = 1'b0;
  always #12.5 clk = ~clk;

  //----------------------------------------------------------------------
  // Instantiate Caravel and SPI Flash
  //----------------------------------------------------------------------

  wire        VDD3V3;
  wire        VDD1V8;
  wire        VSS;
  reg         RSTB;
  reg         CSB;

  wire        gpio;
  wire [37:0] mprj_io;
  wire        uart_tx;
  wire        finished;

  assign uart_tx = mprj_io[6];

  wire        flash_csb;
  wire        flash_clk;
  wire        flash_io0;
  wire        flash_io1;

  caravel uut
  (
    .vddio     (VDD3V3),
    .vddio_2   (VDD3V3),
    .vssio     (VSS),
    .vssio_2   (VSS),
    .vdda      (VDD3V3),
    .vssa      (VSS),
    .vccd      (VDD1V8),
    .vssd      (VSS),
    .vdda1     (VDD3V3),
    .vdda1_2   (VDD3V3),
    .vdda2     (VDD3V3),
    .vssa1     (VSS),
    .vssa1_2   (VSS),
    .vssa2     (VSS),
    .vccd1     (VDD1V8),
    .vccd2     (VDD1V8),
    .vssd1     (VSS),
    .vssd2     (VSS),
    .clock     (clock),
    .gpio      (gpio),
    .mprj_io   (mprj_io),
    .flash_csb (flash_csb),
    .flash_clk (flash_clk),
    .flash_io0 (flash_io0),
    .flash_io1 (flash_io1),
    .resetb    (RSTB)
  );

  spiflash
  #(
    .FILENAME ("chip_code_test.hex")
  )
  spiflash
  (
    .csb (flash_csb),
    .clk (flash_clk),
    .io0 (flash_io0),
    .io1 (flash_io1),
    .io2 (),
    .io3 ()
  );

  // Testbench UART
  uart_print tbuart (
    .ser_rx  (uart_tx),
    .finished(finished)
  );

  //----------------------------------------------------------------------
  // Power-up and reset sequence
  //----------------------------------------------------------------------

  initial begin
    RSTB <= 1'b0;
    CSB  <= 1'b1;   // Force CSB high
    #2000;
    RSTB <= 1'b1;   // Release reset
    #300000;
    CSB = 1'b0;     // CSB can be released
  end

  reg power1;
  reg power2;
  reg power3;
  reg power4;

  initial begin
    power1 <= 1'b0;
    power2 <= 1'b0;
    power3 <= 1'b0;
    power4 <= 1'b0;
    #100;
    power1 <= 1'b1;
    #100;
    power2 <= 1'b1;
    #100;
    power3 <= 1'b1;
    #100;
    power4 <= 1'b1;
  end

  assign VDD3V3 = power1;
  assign VDD1V8 = power2;
  assign VSS    = 1'b0;

  //----------------------------------------------------------------------
  // Setup VCD dumping and overall timeout
  //----------------------------------------------------------------------

  initial begin
    $dumpfile("chip_code_test.vcd");
    $dumpvars(0, chip_code_test_tb);
    #1;

    // Repeat cycles of 1000 clock edges as needed to complete testbench
    repeat (200) begin
      repeat (1000) @(posedge clock);
    end
    $display("%c[1;31m",27);
    `ifdef GL
      $display ("Monitor: Timeout GL Failed");
    `else
      $display ("Monitor: Timeout RTL Failed");
    `endif
    $display("%c[0m",27);
    $finish;
  end

  //----------------------------------------------------------------------
  // Execute the generated VTB cases
  //----------------------------------------------------------------------

  wire [3:0] checkbits;
  reg        reset;

  assign checkbits   = mprj_io[37:36];
  assign mprj_io[10] = clk;
  assign mprj_io[11] = reset;

  initial begin

    // This is how we wait for the firmware to configure the IO ports
    wait (checkbits == 2'h1);

    // Reset the design
    reset = 1'b1;
    #25;
    reset = 1'b0;

    // Wait for the end of the test
    wait (checkbits[1] == 1'b1);

    // Wait for any UART printing to finish
    wait (finished);

    // See if the test passed or not
    if( checkbits[0] == 1'b1 ) begin
      // Indicate success

      $display("%c[1;32m",27);
      $display("  [ passed ]");
      $display("%c[0m",27);
      $finish;
    end

    // Otherwise, indicate failure

    $display("%c[1;31m",27);
    $display("  [ failed ]");
    $display("%c[0m",27);
    $finish;

  end

endmodule

`default_nettype wire

