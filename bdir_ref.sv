// -----------------------------------------------------------------------------
// bidir_full_tb.sv
// Complete self-contained SystemVerilog testbench for a bidirectional line
// ----------------------------------------------------------------------------- 

`timescale 1ns/1ps

// ---------------------
// 1) Interface
// ---------------------
interface bidirectional_intf;
    // data_line must be tri-state to allow DUT tri-state + TB forcing
    tri   data_line;
    logic direction; // 1 = DUT drives (output), 0 = DUT releases (input)
    logic data_out;  // data driven by DUT when direction==1
    logic data_in;   // sampled from data_line by DUT

    // modports for DUT and TB
    // DUT uses direction (input), data_out (input), data_in (output), data_line (inout)
    modport dut_port (
        inout data_line,
        input direction,
        input data_out,
        output data_in
    );

    // TB side: can drive direction/data_out and inout data_line (to emulate external device)
    modport tb_port (
        inout data_line,
        output direction,
        output data_out,
        input  data_in
    );
endinterface

// ---------------------
// 2) DUT module (your module)
// ---------------------
module bidirectional_port (
    inout wire data_line,
    input  wire direction,
    input  wire data_out,
    output wire data_in
);
    // When direction==1 DUT drives data_out onto the bus.
    // When direction==0 DUT releases the bus (Z).
    assign data_line = direction ? data_out : 1'bz;
    // DUT reads whatever is on the bus
    assign data_in = data_line;
endmodule

// ---------------------
// 3) Transaction / Generator
// ---------------------
class transaction;
    rand bit direction;   // 1 -> DUT drives, 0 -> DUT releases (TB ext device drives)
    rand bit data_out;    // value DUT would drive in output mode
    rand bit ext_data;    // value external device will drive in input mode

    function new();
        direction = 0;
        data_out  = 0;
        ext_data  = 0;
    endfunction

    function void display();
        $display("TX: dir=%0b dout=%0b ext=%0b", direction, data_out, ext_data);
    endfunction
endclass

class generator;
    mailbox gen2drv;
    int n_trans;

    function new(mailbox gen2drv, int n=12);
        this.gen2drv = gen2drv;
        this.n_trans = n;
    endfunction

    task run();
        repeat (n_trans) begin
            transaction tr = new();
            assert (tr.randomize()) else $fatal("Randomize failed");
            // bias: ensure we exercise both modes
            gen2drv.put(tr);
            #5;
        end
        // signal end by putting null (optional)
        gen2drv.put(null);
    endtask
endclass

// ---------------------
// 4) Driver
// ---------------------
class driver;
    virtual bidirectional_intf.tb_port vif; // TB-side modport
    mailbox gen2drv;

    function new(virtual bidirectional_intf.tb_port vif, mailbox gen2drv);
        this.vif     = vif;
        this.gen2drv = gen2drv;
    endfunction

    task run();
        transaction tr;
        $display("Driver: started");
        forever begin
            gen2drv.get(tr);
            if (tr == null) begin
                $display("Driver: received null - ending");
                disable fork; // not ideal in classes; will rely on test ending sim
                break;
            end

            // Apply the transaction:
            // If DUT should drive, set direction=1 and provide data_out.
            // If DUT should read (input mode), set direction=0 and act as external device
            if (tr.direction == 1) begin
                // Ensure bus is free for DUT to drive: release any TB forced value then drive direction/data_out
                // Release data_line (if previously forced) before allowing DUT to drive
                release vif.data_line;
                vif.direction = 1;
                vif.data_out  = tr.data_out;
                // Hold for some cycles to allow monitor/scoreboard sample
                #6;
                // After driving, optionally release DUT (left to next transaction)
            end else begin
                // Input mode: DUT releases bus. TB (this driver) must force external data onto bus.
                vif.direction = 0;
                // Ensure DUT is in Z state before forcing: small delay
                #1;
                force vif.data_line = tr.ext_data;
                // Keep external device driving for a short window
                #6;
                release vif.data_line;
            end

            // small gap between transactions
            #2;
        end
    endtask
endclass

// ---------------------
// 5) Monitor
// ---------------------
class monitor;
    virtual bidirectional_intf.tb_port vif;
    mailbox mon2scb;

    function new(virtual bidirectional_intf.tb_port vif, mailbox mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        $display("Monitor: started");
        forever begin
            // sample periodically (aligned with driver timing)
            #2;
            // Pack snapshot into 4-bit vector: dir,dout,line,in
            bit direction  = vif.direction;
            bit data_out   = vif.data_out;
            tri data_line  = vif.data_line;
            bit data_in    = vif.data_in;
            mon2scb.put({direction, data_out, data_line, data_in});
        end
    endtask
endclass

// ---------------------
// 6) Scoreboard
// ---------------------
class scoreboard;
    mailbox mon2scb;
    int pass_count = 0;
    int fail_count = 0;

    function new(mailbox mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    task run();
        bit direction, data_out, data_line, data_in;
        $display("Scoreboard: started");
        forever begin
            mon2scb.get({direction, data_out, data_line, data_in});
            // Evaluate correctness:
            if (direction == 1) begin
                // DUT driving: line and data_in should follow data_out
                if ((data_line === data_out) && (data_in === data_out)) begin
                    pass_count++;
                    $display("PASS @%0t | OUT mode dir=1 dout=%0b line=%0b din=%0b", $time, data_out, data_line, data_in);
                end else begin
                    fail_count++;
                    $display("FAIL @%0t | OUT mode dir=1 dout=%0b line=%0b din=%0b", $time, data_out, data_line, data_in);
                end
            end else begin
                // Input mode: DUT released; external TB drove the bus.
                // Check DUT readback equals actual line value.
                if (data_in === data_line) begin
                    pass_count++;
                    $display("PASS @%0t | IN mode dir=0 line=%0b din=%0b", $time, data_line, data_in);
                end else begin
                    fail_count++;
                    $display("FAIL @%0t | IN mode dir=0 line=%0b din=%0b", $time, data_line, data_in);
                end
            end
        end
    endtask

    task report();
        $display("\n=== SCOREBOARD REPORT ===");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("=========================\n");
    endtask
endclass

// ---------------------
// 7) Environment
// ---------------------
class environment;
    generator gen;
    driver    drv;
    monitor   mon;
    scoreboard scb;

    virtual bidirectional_intf.tb_port vif;

    mailbox gen2drv;
    mailbox mon2scb;

    function new(virtual bidirectional_intf.tb_port vif);
        this.vif = vif;
        gen2drv  = new();
        mon2scb  = new();
    endfunction

    function void build();
        gen = new(gen2drv, 16);         // generate 16 transactions
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);
    endfunction

    task run();
        // run everything in parallel
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_any

        // allow a little time to drain mailboxes and let monitor/scoreboard finish
        #40;
        scb.report();
    endtask
endclass

// ---------------------
// 8) Test
// ---------------------
class test;
    environment env;
    virtual bidirectional_intf.tb_port vif;

    function new(virtual bidirectional_intf.tb_port vif);
        this.vif = vif;
    endfunction

    task build();
        $display("Test: building environment");
        env = new(vif);
        env.build();
    endtask

    task run();
        $display("Test: running environment");
        env.run();
    endtask
endclass

// ---------------------
// 9) Top-level TB
// ---------------------
module tb;
    // instantiate interface
    bidirectional_intf vif();

    // instantiate DUT (connect to interface signals)
    bidirectional_port dut (
        .data_line(vif.data_line),
        .direction(vif.direction),
        .data_out(vif.data_out),
        .data_in(vif.data_in)
    );

    test t;

    initial begin
        $display("\n===== Starting simulation =====\n");
        $dumpfile("bidir_tb.vcd");
        $dumpvars(0, tb);

        // Initialize interface signals
        vif.direction = 0;
        vif.data_out  = 0;
        release vif.data_line;

        // create and run test
        t = new(vif.tb_port);
        t.build();
        t.run();

        #100;
        $display("\n===== Simulation finished =====\n");
        $finish;
    end
endmodule
