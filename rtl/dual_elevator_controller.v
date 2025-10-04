`include "rtl/defs.vh"

module dual_elevator_controller(
    input clk,
    input rst,
    input [`FLOORS-1:0] hall_up,   // hall calls up
    input [`FLOORS-1:0] hall_down, // hall calls down
    input [`FLOORS-1:0] car1_req,  // direct car requests
    input [`FLOORS-1:0] car2_req,
    output [`FLOORS-1:0] car1_assign, // requests assigned to car1
    output [`FLOORS-1:0] car2_assign,
    output [2:0] car1_floor,
    output [2:0] car2_floor,
    output car1_moving,
    output car2_moving
);

    // Simple scheduler: combine hall calls and car requests into a single request mask
    wire [`FLOORS-1:0] combined = hall_up | hall_down | car1_req | car2_req;

    // Very simple assignment: split floors 0..(FLOORS/2-1) -> car1, rest -> car2
    localparam MID = `FLOORS/2;

    reg [`FLOORS-1:0] assign1, assign2;

    integer j;
    always @(*) begin
        assign1 = 0; assign2 = 0;
        for (j=0;j<`FLOORS;j=j+1) begin
            if (j < MID)
                assign1[j] = combined[j];
            else
                assign2[j] = combined[j];
        end
    end

    // Instantiate elevator cars
    elevator_car #(.ID(1)) car1(
        .clk(clk), .rst(rst), .requests(assign1), .pending(), .current_floor(car1_floor), .moving(car1_moving)
    );

    elevator_car #(.ID(2)) car2(
        .clk(clk), .rst(rst), .requests(assign2), .pending(), .current_floor(car2_floor), .moving(car2_moving)
    );

    assign car1_assign = assign1;
    assign car2_assign = assign2;

endmodule
