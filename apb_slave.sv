module apb_slave (
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [7:0]  PADDR,
    input  logic [7:0]  PWDATA,
    output logic [7:0]  PRDATA,
    output logic        PREADY,

    output logic        tx_start,
    output logic [7:0]  tx_data,
    input  logic        tx_busy
);

    logic [7:0] reg0;

    assign PREADY = 1'b1;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg0 <= 0;
            PRDATA <= 0;
            tx_start <= 0;
        end else begin
            tx_start <= 0;

            // WRITE
            if (PSEL && PENABLE && PWRITE) begin
                if (PADDR == 8'h08) begin
                    reg0 <= PWDATA;

                    if (!tx_busy) begin
                        tx_data  <= PWDATA;
                        tx_start <= 1;
                    end
                end
            end

            // READ
            if (PSEL && PENABLE && !PWRITE) begin
                if (PADDR == 8'h08)
                    PRDATA <= reg0;
                else
                    PRDATA <= 8'h00;
            end
        end
    end
endmodule