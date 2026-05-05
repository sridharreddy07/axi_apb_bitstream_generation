module uart_rx_with_baud(
    input  logic clk,        // 50 MHz
    input  logic rst,
    input  logic rx,         // UART RX line
    output logic [7:0] data_out,
    output logic data_valid  // 1-cycle pulse when byte received
);

    parameter BAUD_DIV = 5208;

    logic [12:0] baud_count;
    logic baud_tick;

    // Baud generator
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

    // FSM
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [7:0] shift_reg;
    logic [3:0] bit_cnt;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            data_out <= 0;
            data_valid <= 0;
            bit_cnt <= 0;
        end else begin
            data_valid <= 0;

            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        if (rx == 0) // start bit detect
                            state <= START;
                    end

                    START: begin
                        if (rx == 0) begin
                            bit_cnt <= 0;
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end

                    DATA: begin
                        shift_reg <= {rx, shift_reg[7:1]};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7)
                            state <= STOP;
                    end

                    STOP: begin
                        if (rx == 1) begin
                            data_out <= shift_reg;
                            data_valid <= 1;
                        end
                        state <= IDLE;
                    end
                endcase
            end
        end
    end

endmodule