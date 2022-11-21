//-----------------------------------------------------------------
// utils.h
//-----------------------------------------------------------------
// Declaration of utility functions for testing

#ifndef UTILS_H
#define UTILS_H

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

// Helper functions for printing
void print_config();

// Imported from stub.c
void print( const char* p);
// WARNING: This takes a while! Only use if necessary
// All strings transmitted must end in a newline (\n)

#endif // UTILS_H