/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>

/*
	RegInc Adhoc Test
         - Observe that a basic test is adhered to
*/

int clk = 0;
int i;

void main()
{

        // Clock and Reset signals come from outside the chip
        reg_mprj_io_10 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
        reg_mprj_io_11 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;

        // GPIO's 28-31 are used as outputs to send signals to outside
        reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;

        // GPIO's 24-27 are used as inputs to receive signals from outside
        reg_mprj_io_27 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
        reg_mprj_io_26 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
        reg_mprj_io_25 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
        reg_mprj_io_24 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
        

        /* Apply GPIO configuration */
        reg_mprj_xfer = 1;
        while (reg_mprj_xfer == 1);

	// Configure LA probes [31:0]  as outputs from the cpu 
        // Configure LA probes [63:32] as outputs from the cpu 
	reg_la0_oenb = reg_la0_iena = 0xFFFFFFFF;    // [31:0]
	reg_la1_oenb = reg_la1_iena = 0x00000000;    // [63:32]

	// Flag start of the test
	reg_mprj_datal = 0xA0000000;

        // Verilog handles resetting the design

        // Set data going in
        reg_la0_data = 0x12345678;

        // Observe outputs
        while (1) {
		if (reg_la1_data_in == 0x12345679) {
			reg_mprj_datal = 0xB0000000;
			break;
		}
	}

}
