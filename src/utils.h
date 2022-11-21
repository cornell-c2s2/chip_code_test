//-----------------------------------------------------------------
// utils.h
//-----------------------------------------------------------------
// Declaration of utility functions for testing

#include <stdint.h>
#include <defs.h>

// Configure GPIO for testing
void test_config();

// Signal start of the test
void test_start();

// Various test checks
void test_pass();
void test_fail();

// Will only stop the test if it's a fail
void test_reg_eq( uint32_t value_1, uint32_t value_2 );
void test_int_eq(      int value_1,      int value_2 );
