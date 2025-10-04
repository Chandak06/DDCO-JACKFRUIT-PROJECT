`timescale 1ns/1ps
`include "rtl/defs.vh"

module dual_elevator_tb;
    reg clk = 0;
    reg rst = 1;

    reg [`FLOORS-1:0] hall_up;
    reg [`FLOORS-1:0] hall_down;
    reg [`FLOORS-1:0] car1_req;
    reg [`FLOORS-1:0] car2_req;

    wire [`FLOORS-1:0] car1_assign;
    wire [`FLOORS-1:0] car2_assign;
    wire [2:0] car1_floor;
    wire [2:0] car2_floor;
    wire car1_moving, car2_moving;

    dual_elevator_controller dut(
        .clk(clk), .rst(rst), .hall_up(hall_up), .hall_down(hall_down), .car1_req(car1_req), .car2_req(car2_req),
        .car1_assign(car1_assign), .car2_assign(car2_assign), .car1_floor(car1_floor), .car2_floor(car2_floor), .car1_moving(car1_moving), .car2_moving(car2_moving)
    );

    // clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dual_elevator.vcd");
        $dumpvars(0, dut);

        hall_up = 0; hall_down = 0; car1_req = 0; car2_req = 0;

        #12 rst = 0;

        // sequence of calls
        #10 hall_up[2] = 1; // call at floor 2 up
        #50 hall_down[5] = 1; // call at top floor down
        #50 car1_req[0] = 1; // car1 direct request to floor 0
        #80 hall_up[1] = 1; // another call

        #500 $finish;
    end

    // simple monitor
    always @(posedge clk) begin
        if (!rst) begin
            $display("time=%0t car1_floor=%0d car2_floor=%0d car1_m=%b car2_m=%b car1_assign=%b car2_assign=%b", $time, car1_floor, car2_floor, car1_moving, car2_moving, car1_assign, car2_assign);
        end
    end

endmodule
