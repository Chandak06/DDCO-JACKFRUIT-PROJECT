`include "defs.vh"

module dual_elevator_controller(
    input clk,
    input rst,
    input [`FLOORS-1:0] hall_up,
    input [`FLOORS-1:0] hall_down,
    input [`FLOORS-1:0] car1_req,
    input [`FLOORS-1:0] car2_req,
    output [`FLOORS-1:0] car1_assign,
    output [`FLOORS-1:0] car2_assign,
    output [2:0] car1_floor,
    output [2:0] car2_floor,
    output car1_moving,
    output car2_moving
);

    reg [`FLOORS-1:0] pending_hall_up;
    reg [`FLOORS-1:0] pending_hall_down;
    reg [`FLOORS-1:0] pending_car1_req;
    reg [`FLOORS-1:0] pending_car2_req;

    wire [`FLOORS-1:0] car1_serviced;
    wire [`FLOORS-1:0] car2_serviced;
    wire [`FLOORS-1:0] any_serviced = car1_serviced | car2_serviced;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pending_hall_up   <= 0;
            pending_hall_down <= 0;
            pending_car1_req  <= 0;
            pending_car2_req  <= 0;
        end else begin
            pending_hall_up   <= (pending_hall_up   | hall_up)   & ~any_serviced;
            pending_hall_down <= (pending_hall_down | hall_down) & ~any_serviced;
            pending_car1_req  <= (pending_car1_req  | car1_req)  & ~car1_serviced;
            pending_car2_req  <= (pending_car2_req  | car2_req)  & ~car2_serviced;
        end
    end

    wire [`FLOORS-1:0] all_hall_calls = pending_hall_up | pending_hall_down;
    localparam MID = `FLOORS/2;
    reg [`FLOORS-1:0] assign1_comb, assign2_comb;
    integer j;

    always @(*) begin
        assign1_comb = 0; 
        assign2_comb = 0;
        for (j = 0; j < `FLOORS; j = j + 1) begin
            if (j < MID)
                assign1_comb[j] = all_hall_calls[j];
            else
                assign2_comb[j] = all_hall_calls[j];
        end
        assign1_comb = assign1_comb | pending_car1_req;
        assign2_comb = assign2_comb | pending_car2_req;
    end

    assign car1_assign = assign1_comb;
    assign car2_assign = assign2_comb;

    elevator_car #(.ID(1)) car1(
        .clk(clk), 
        .rst(rst), 
        .requests(car1_assign), 
        .current_floor(car1_floor), 
        .moving(car1_moving),
        .serviced(car1_serviced)
    );

    elevator_car #(.ID(2)) car2(
        .clk(clk), 
        .rst(rst), 
        .requests(car2_assign), 
        .current_floor(car2_floor), 
        .moving(car2_moving),
        .serviced(car2_serviced)
    );

endmodule
