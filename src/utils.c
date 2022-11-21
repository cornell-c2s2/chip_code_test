//-----------------------------------------------------------------
// utils.c
//-----------------------------------------------------------------
// Utility functions for testing

#include "utils.h"

//-----------------------------------------------------------------
// test_config
//-----------------------------------------------------------------
// Configures GPIO 37-36 for signaling test results. 
// We use GPIO 37 to signal that the test is complete, and GPIO 36
// to signal whether it passed or not

void test_config()
{
    // GPIO's 37-36 are used as outputs to send signals to the
    // test harness
    reg_mprj_io_37 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_36 = GPIO_MODE_MGMT_STD_OUTPUT;

    // Transfer configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);
}

//-----------------------------------------------------------------
// test_start
//-----------------------------------------------------------------
// Signals to the test harness that the test has started, so it can
// take any necessary actions, such as resetting the design
// We do this by setting GPIO 37 to 0, and GPIO 36 to 1

void test_start()
{
    // Get current GPIO data to avoid changing
    uint32_t temp = reg_mprj_datah;

    // Mask registers appropriately
    //  - GPIO 37: 0 (Test not complete)
    //  - GPIO 36: 1 (Test start)
    temp = ( temp | 0x00000010 ) & 0xFFFFFFDF;

    // Apply signals
    reg_mprj_datah = temp;
}

//-----------------------------------------------------------------
// test_pass
//-----------------------------------------------------------------
// Signals to the test harness that all tests have passed

void test_pass()
{
    // Get current GPIO data to avoid changing
    uint32_t temp = reg_mprj_datah;

    // Mask registers appropriately
    //  - GPIO 37: 1 (Test complete)
    //  - GPIO 36: 1 (Tests passed)
    temp = ( temp | 0x00000030 );

    // Apply signals
    reg_mprj_datah = temp;
}

//-----------------------------------------------------------------
// test_fail
//-----------------------------------------------------------------
// Signals to the test harness that a test failed

void test_fail()
{   
    // Get current GPIO data to avoid changing
    uint32_t temp = reg_mprj_datah;

    // Mask registers appropriately
    //  - GPIO 37: 1 (Test complete)
    //  - GPIO 36: 0 (Test failed)
    temp = ( temp | 0x00000020 ) & 0xFFFFFFEF;

    // Apply signals
    reg_mprj_datah = temp;
}

//-----------------------------------------------------------------
// test_reg_eq
//-----------------------------------------------------------------
// Tests whether two register values (uint32_t) are equal or not
// No effect if equal, fails the test if not

void test_reg_eq( uint32_t value_1, uint32_t value_2 )
{
    if( value_1 != value_2 ){
        test_fail();
    }
}

//-----------------------------------------------------------------
// test_int_eq
//-----------------------------------------------------------------
// Tests whether two int values are equal or not
// No effect if equal, fails the test if not

void test_int_eq( int value_1, int value_2 )
{
    if( value_1 != value_2 ){
        test_fail();
    }
}

//-----------------------------------------------------------------
// print_config
//-----------------------------------------------------------------
// Configures GPIO 6 to send characters to harness over UART

void print_config()
{
    // Enable UART
    reg_uart_enable = 1;

    // Set GPIO 6 (UART from mgmt) as MGMT Output
    
    reg_mprj_io_6 = GPIO_MODE_MGMT_STD_OUTPUT;
    
    // Transfer configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);
}

//-----------------------------------------------------------------
// putchar
//-----------------------------------------------------------------
// Sends a character over UART

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
    while (reg_uart_txfull == 1);
	reg_uart_data = c;
}

//-----------------------------------------------------------------
// print
//-----------------------------------------------------------------
// Sends a string over UART to be printed by the test harness

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}