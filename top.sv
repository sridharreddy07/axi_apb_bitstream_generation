module top (
    input  logic clk,
    input  logic reset,
    input  logic uart_rx,
    output logic uart_tx
);

    // UART RX
    logic [7:0] rx_data;
    logic rx_valid;

    uart_rx_with_baud u_rx (
        .clk(clk),
        .rst(reset),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    // AXI signals
    logic [7:0] AWADDR, WDATA;
    logic AWVALID, WVALID;
    logic AWREADY, WREADY;
    logic BVALID;
    logic BREADY;

    assign BREADY = 1'b1;

    // Simple command parser
    logic [1:0] byte_cnt;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_cnt <= 0;
            AWVALID <= 0;
            WVALID  <= 0;
        end else begin
            AWVALID <= 0;
            WVALID  <= 0;

            if (rx_valid) begin
                case (byte_cnt)
                    0: begin
                        AWADDR <= rx_data;
                        byte_cnt <= 1;
                    end
                    1: begin
                        WDATA <= rx_data;
                        AWVALID <= 1;
                        WVALID  <= 1;
                        byte_cnt <= 0;
                    end
                endcase
            end
        end
    end

    // APB signals
    logic [7:0] paddr, pwdata, prdata;
    logic psel, penable, pwrite, pready;

    // Bridge
    axi_to_apb_bridge bridge (
        .ACLK(clk),
        .ARESETn(~reset),

        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),

        .BVALID(BVALID),
        .BREADY(BREADY),

        .ARADDR(8'h00),
        .ARVALID(1'b0),
        .ARREADY(),
        .RDATA(),
        .RVALID(),
        .RREADY(1'b0),

        .PSEL(psel),
        .PENABLE(penable),
        .PWRITE(pwrite),
        .PADDR(paddr),
        .PWDATA(pwdata),
        .PRDATA(prdata),
        .PREADY(pready)
    );

    // UART TX signals
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;

    // APB Slave
    apb_slave slave (
        .PCLK(clk),
        .PRESETn(~reset),

        .PSEL(psel),
        .PENABLE(penable),
        .PWRITE(pwrite),
        .PADDR(paddr),
        .PWDATA(pwdata),
        .PRDATA(prdata),
        .PREADY(pready),

        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy)
    );

    // UART TX
    uart_tx_with_baud uart_tx_inst (
        .clk(clk),
        .rst(reset),
        .tx_start(tx_start),
        .data_in(tx_data),
        .tx(uart_tx),
        .busy(tx_busy)
    );

endmodule