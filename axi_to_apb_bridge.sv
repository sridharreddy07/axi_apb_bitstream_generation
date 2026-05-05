module axi_to_apb_bridge (

    input  logic ACLK,
    input  logic ARESETn,

    // ---------------- AXI WRITE ----------------
    input  logic [7:0] AWADDR,
    input  logic       AWVALID,
    output logic       AWREADY,

    input  logic [7:0] WDATA,
    input  logic       WVALID,
    output logic       WREADY,

    output logic       BVALID,
    input  logic       BREADY,

    // ---------------- AXI READ ----------------
    input  logic [7:0] ARADDR,
    input  logic       ARVALID,
    output logic       ARREADY,

    output logic [7:0] RDATA,
    output logic       RVALID,
    input  logic       RREADY,

    // ---------------- APB ----------------
    output logic       PSEL,
    output logic       PENABLE,
    output logic       PWRITE,
    output logic [7:0] PADDR,
    output logic [7:0] PWDATA,

    input  logic [7:0] PRDATA,
    input  logic       PREADY
);

    typedef enum logic [2:0] {
        IDLE,
        WRITE_SETUP,
        WRITE_ACCESS,
        WRITE_RESP,
        READ_SETUP,
        READ_ACCESS,
        READ_CAPTURE,   // ? FIXED STATE
        READ_RESP
    } state_t;

    state_t state;

    // ---------------- RESET ----------------
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state   <= IDLE;

            PSEL    <= 0;
            PENABLE <= 0;

            AWREADY <= 0;
            WREADY  <= 0;
            BVALID  <= 0;

            ARREADY <= 0;
            RVALID  <= 0;
            RDATA   <= 0;
        end
        else begin
            case (state)

                // ================= IDLE =================
                IDLE: begin
                    AWREADY <= 1;
                    WREADY  <= 1;
                    ARREADY <= 1;

                    if (AWVALID && WVALID) begin
                        // WRITE start
                        AWREADY <= 0;
                        WREADY  <= 0;

                        PADDR   <= AWADDR;
                        PWDATA  <= WDATA;
                        PWRITE  <= 1;

                        PSEL    <= 1;
                        PENABLE <= 0;

                        state <= WRITE_SETUP;
                    end
                    else if (ARVALID) begin
                        // READ start
                        ARREADY <= 0;

                        PADDR   <= ARADDR;
                        PWRITE  <= 0;

                        PSEL    <= 1;
                        PENABLE <= 0;

                        state <= READ_SETUP;
                    end
                end

                // ================= WRITE =================
                WRITE_SETUP: begin
                    PENABLE <= 1;
                    state   <= WRITE_ACCESS;
                end

                WRITE_ACCESS: begin
                    if (PREADY) begin
                        PSEL    <= 0;
                        PENABLE <= 0;

                        BVALID  <= 1;
                        state   <= WRITE_RESP;
                    end
                end

                WRITE_RESP: begin
                    if (BREADY) begin
                        BVALID <= 0;
                        state  <= IDLE;
                    end
                end

                // ================= READ =================
                READ_SETUP: begin
                    PENABLE <= 1;
                    state   <= READ_ACCESS;
                end

                READ_ACCESS: begin
                    if (PREADY) begin
                        // ? wait one cycle before sampling PRDATA
                        state <= READ_CAPTURE;
                    end
                end

                // ? CRITICAL FIX STATE
                READ_CAPTURE: begin
                    // PRDATA is now stable
                    RDATA <= PRDATA;

                    PSEL    <= 0;
                    PENABLE <= 0;

                    RVALID <= 1;
                    state  <= READ_RESP;
                end

                READ_RESP: begin
                    if (RREADY) begin
                        RVALID <= 0;
                        state  <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule