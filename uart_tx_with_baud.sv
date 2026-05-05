`timescale 1ns/1ps
module uart_tx_with_baud(
    input  logic clk,        // 50 MHz clock
    input  logic rst,        // active high reset
    input  logic tx_start,   // pulse to start sending 1 byte
    input  logic [7:0] data_in,
    output logic tx,         // UART TX line
    output logic busy        // high while transmitting
);

    // ---------------- Baud generator ----------------
    parameter BAUD_DIV = 5208; // 50MHz / 9600 baud
    logic [12:0] baud_count;   // 13-bit counter
    logic baud_tick;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_count <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_count == BAUD_DIV-1) begin
                baud_count <= 0;
                baud_tick <= 1;
            end else begin
                baud_count <= baud_count + 1;
                baud_tick <= 0;
            end
        end
    end

    // ----------- UART TX FSM -------------
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;
    logic [7:0] shift_reg;
    logic [3:0] bit_cnt;
    logic start_latched;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1;        // idle high
            busy <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
            start_latched <= 0;
        end else begin
            // latch tx_start until baud_tick
            if (tx_start)
                start_latched <= 1;
            
            if (baud_tick) begin
                case(state)
                    IDLE: begin
                        tx <= 1;
                        busy <= 0;
                        if (start_latched) begin
                            shift_reg <= data_in;
                            busy <= 1;
                            state <= START;
                            start_latched <= 0;
                        end
                    end
                    START: begin
                        tx <= 0;       // start bit
                        bit_cnt <= 0;
                        state <= DATA;
                    end
                    DATA: begin
                        tx <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7)
                            state <= STOP;
                    end
                    STOP: begin
                        tx <= 1;       // stop bit
                        state <= IDLE;
                    end
                endcase
            end
        end
    end

endmodule
