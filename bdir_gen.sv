class transaction;
    rand bit direction;
    rand bit data_out;

    function void display();
        $display("TX: direction=%0b data_out=%0b", direction, data_out);
    endfunction
endclass


class generator;

    mailbox gen2drv;
    int count;

    function new(mailbox gen2drv);
        this.gen2drv = gen2drv;
        count = 10;    // 10 random tests
    endfunction

    task run();
        repeat(count) begin
            transaction tr = new();
            assert(tr.randomize());
            tr.display();
            gen2drv.put(tr);
            #5;
        end
    endtask

endclass
