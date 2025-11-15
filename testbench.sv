module tb_bidirectional_port;

    wire data_line;
    reg direction;
    reg data_out;
    wire data_in;
    
    reg external_data;
    reg external_drive;
    
    assign data_line = external_drive ? external_data : 1'bz;

    bidirectional_port dut (
        .data_line(data_line),
        .direction(direction),
        .data_out(data_out),
        .data_in(data_in)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_bidirectional_port);
        
        direction = 0;
        data_out = 0;
        external_data = 0;
        external_drive = 0;
        
        $display("=== Bidirectional Port Testbench ===\n");
        
        $display("Test 1: OUTPUT MODE (direction=1)");
        direction = 1;
        external_drive = 0;
        
        data_out = 0;
        #10;
        $display("Time=%0t | Direction=%b | data_out=%b | data_line=%b | data_in=%b", 
                 $time, direction, data_out, data_line, data_in);
        
        data_out = 1;
        #10;
        $display("Time=%0t | Direction=%b | data_out=%b | data_line=%b | data_in=%b", 
                 $time, direction, data_out, data_line, data_in);
        
        $display("\nTest 2: INPUT MODE (direction=0)");
        direction = 0;
        external_drive = 1;
        
        external_data = 0;
        #10;
        $display("Time=%0t | Direction=%b | external_data=%b | data_line=%b | data_in=%b", 
                 $time, direction, external_data, data_line, data_in);
        
        external_data = 1;
        #10;
        $display("Time=%0t | Direction=%b | external_data=%b | data_line=%b | data_in=%b", 
                 $time, direction, external_data, data_line, data_in);
        
        $display("\nTest 3: TRANSITION (Output -> Input)");
        direction = 1;
        data_out = 1;
        external_drive = 0;
        #10;
        $display("Time=%0t | Mode=OUTPUT | data_line=%b", $time, data_line);
        
        direction = 0;
        #1;
        external_drive = 1;
        external_data = 0;
        #10;
        $display("Time=%0t | Mode=INPUT | data_line=%b (No contention)", $time, data_line);
        
        $display("\nTest 4: MULTIPLE TRANSITIONS");
        repeat(4) begin
            direction = 1;
            external_drive = 0;
            data_out = $random;
            #10;
            $display("Time=%0t | OUTPUT | data_out=%b -> data_line=%b", 
                     $time, data_out, data_line);
            
            direction = 0;
            #1;
            external_drive = 1;
            external_data = $random;
            #10;
            $display("Time=%0t | INPUT  | external_data=%b -> data_in=%b", 
                     $time, external_data, data_in);
        end
        
        $display("\n=== All Tests Completed ===");
        $finish;
    end
    
    always @(*) begin
        if (direction && external_drive) begin
            $display("WARNING: Bus contention at time %0t!", $time);
        end
    end

endmodule