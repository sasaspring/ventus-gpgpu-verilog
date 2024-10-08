
`define drv_gpu               u_host_inter.drv_gpu
`define exe_finish            u_host_inter.exe_finish
`define get_result_addr       u_host_inter.get_result_addr
`define parsed_base           u_host_inter.parsed_base_r
`define parsed_size           u_host_inter.parsed_size_r

`define init_mem             u_mem_inter.init_mem
`define tile_read_and_write  u_mem_inter.tile_read_and_write
`define mem                  u_mem_inter.mem
//`define l2_flush_finish      gpu_test.B1[0].l2cache.SourceD_finish_issue_o
`define host_rsp_valid        u_host_inter.host_rsp_valid_o

//**********Selsct nn test case, remember modify `define NUM_THREAD at the same time**********//
`define CASE_8W4T
//`define CASE_2W16T
//`define CASE_4W8T
//`define CASE_4W16T
//`define CASE_8W8T


module tc;
  //parameter MAX_NUM_BUF     = 10; //the maximun of num_buffer
  //parameter MEM_ADDR        = 32;
  parameter METADATA_SIZE   = 1024; //the maximun size of .data
  parameter DATADATA_SIZE   = 2000; //the maximun size of .metadata

  parameter META_FNAME_SIZE = 128;
  parameter DATA_FNAME_SIZE = 128;

  parameter BUF_NUM         = 18;

  defparam u_host_inter.META_FNAME_SIZE = META_FNAME_SIZE;
  defparam u_host_inter.DATA_FNAME_SIZE = DATA_FNAME_SIZE;
  defparam u_host_inter.METADATA_SIZE   = METADATA_SIZE;
  defparam u_host_inter.DATADATA_SIZE   = DATADATA_SIZE;

  defparam u_mem_inter.META_FNAME_SIZE = META_FNAME_SIZE;
  defparam u_mem_inter.DATA_FNAME_SIZE = DATA_FNAME_SIZE;
  defparam u_mem_inter.METADATA_SIZE   = METADATA_SIZE;
  defparam u_mem_inter.DATADATA_SIZE   = DATADATA_SIZE;
  defparam u_mem_inter.BUF_NUM         = BUF_NUM;

  wire clk  = u_gen_clk.clk;
  wire rstn = u_gen_rst.rst_n;
 
  //reg [31:0] mem_metadata [0:METADATA_SIZE-1];
  //reg [31:0] mem_data     [0:DATADATA_SIZE-1];
  reg [META_FNAME_SIZE*8-1:0] meta_fname[7:0];
  reg [DATA_FNAME_SIZE*8-1:0] data_fname[7:0];

  initial begin
    repeat(500)
    @(posedge clk);
    init_test_file();
    test_nn();
    repeat(500)
    @(posedge clk);
    $finish();
  end

  initial begin
    //repeat(500)
    //@(posedge clk);
    mem_drv();
  end

  //initial begin
  //  #1000000;
  //  $finish;
  //end 

  task init_test_file;
    begin
      `ifdef CASE_8W4T
        meta_fname[0] = "8w4t/NearestNeighbor_0.metadata";
        data_fname[0] = "8w4t/NearestNeighbor_0.data";
      `endif
      `ifdef CASE_2W16T
        meta_fname[0] = "2w16t/NearestNeighbor_0.metadata";
        data_fname[0] = "2w16t/NearestNeighbor_0.data";
      `endif
      `ifdef CASE_4W8T
        meta_fname[0] = "4x8/NearestNeighbor_0.metadata";
        data_fname[0] = "4x8/NearestNeighbor_0.data";
      `endif
      `ifdef CASE_4W16T
        meta_fname[0] = "4x16/NearestNeighbor_0.metadata";
        data_fname[0] = "4x16/NearestNeighbor_0.data";
      `endif
      `ifdef CASE_8W8T
        meta_fname[0] = "8x8/NearestNeighbor_0.metadata";
        data_fname[0] = "8x8/NearestNeighbor_0.data";
      `endif

    end
  endtask

  task test_nn;
    integer i;
    begin
      for(i=0; i<1; i=i+1) begin
        `init_mem(meta_fname[i], data_fname[i]);
        `drv_gpu(meta_fname[i], data_fname[i]);
        if(i==0) begin
          `get_result_addr(meta_fname[i], data_fname[i]);
        end
        `exe_finish(meta_fname[i], data_fname[i]);
        if(i==0) begin
          print_result();
        end
      end
    end
  endtask

  task mem_drv;
    begin
      while(1) fork
        `tile_read_and_write(0);
      join
    end
  endtask

  //task print_mem;
  //  if(`l2_flush_finish) begin
  //    $display("-case_gaussian result-");
  //    $display("-----matrix a:-----");
  //    for(integer addr=32'h90000000; addr<32'h90000000+32'h40; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    $display("-----array b:-----");
  //    for(integer addr=32'h90001000; addr<32'h90001000+32'h10; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    $display("-----tmp value:-----");
  //    for(integer addr=32'h90002000; addr<32'h90002000+32'h40; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    $display("============================================");
  //  end
  //endtask

  task print_result;
    reg [31:0]    result_19_soft [18:0] ;
    reg [31:0]    result_19_hard [18:0] ;
    reg [18:0]    result_19_pass        ;

    reg [31:0]    result_28_soft [27:0] ;
    reg [31:0]    result_28_hard [27:0] ;
    reg [27:0]    result_28_pass        ;

    reg [31:0]    result_53_soft [52:0] ;
    reg [31:0]    result_53_hard [52:0] ;
    reg [52:0]    result_53_pass        ;
   
    result_19_soft  = {32'h421841d5,32'h425f3d4b,32'h4262d4c0,32'h41f162a4,32'h4374559a,32'h4268bf40,32'h4376a596,32'h43146968,32'h41756be4,32'h434c306a,32'h42ac21d5,32'h42642ba4,32'h40fbe842,32'h42a1a288,32'h432b202e,32'h41ee4460,32'h4362bf30,32'h41c9a01b,32'h436ea041};
    result_28_soft  = {32'h421841d5,32'h425f3d4b,32'h4262d4c0,32'h41f162a4,32'h4374559a,32'h4268bf40,32'h4376a596,32'h43146968,32'h41756be4,32'h434c306a,32'h42ac21d5,32'h42642ba4,32'h40fbe842,32'h42a1a288,32'h432b202e,32'h41ee4460,32'h41b08224,32'h41a2eee1,32'h420a87ae,32'h4327f4e2,32'h42a32e6e,32'h42b1427b,32'h42d7b7d2,32'h432b76ee,32'h42867b28,32'h4362bf30,32'h41c9a01b,32'h436ea041};
    result_53_soft  = {32'h421841d5,32'h425f3d4b,32'h4262d4c0,32'h41f162a4,32'h4374559a,32'h4268bf40,32'h4376a596,32'h43146968,32'h41756be4,32'h434c306a,32'h42ac21d5,32'h42642ba4,32'h40fbe842,32'h42a1a288,32'h432b202e,32'h41ee4460,32'h41b08224,32'h41a2eee1,32'h420a87ae,32'h4327f4e2,32'h42a32e6e,32'h42b1427b,32'h42d7b7d2,32'h432b76ee,32'h42867b28,32'h42dc70eb,32'h41093570,32'h433b8444,32'h4194008d,32'h42353c5c,32'h4217b8cb,32'h437c266f,32'h42943571,32'h429546e5,32'h42d2176c,32'h43537016,32'h437e83f1,32'h4279c552,32'h437de865,32'h42992ffd,32'h435299af,32'h41e88118,32'h42960c75,32'h4293aacd,32'h424b9c1c,32'h42d03ab4,32'h436fd2ba,32'h43271ed7,32'h4348b01d,32'h41a1b26f,32'h4362bf30,32'h41c9a01b,32'h436ea041};

    //if(`l2_flush_finish) begin
    if(`host_rsp_valid) begin
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      $display("-------------case_nn result--------------");
      $display("----------------distance :---------------");
      for(integer addr=`parsed_base[1]; addr<`parsed_base[1]+`parsed_size[1]; addr=addr+4) begin
        //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        $display("          0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        `ifdef CASE_8W4T
          result_19_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `endif
        `ifdef CASE_2W16T
          result_19_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `endif
        `ifdef CASE_4W8T
          result_28_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `endif
        `ifdef CASE_4W16T
          result_53_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `endif
        `ifdef CASE_8W8T
          result_53_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `endif
      end

      `ifdef CASE_8W4T
              for(integer j=0; j<19; j=j+1) begin        
                if(result_19_hard[j]==result_19_soft[18-j]) begin
                  result_19_pass[j]  = 1'b1;
                end else begin
                  result_19_pass[j]  = 1'b0;
                end
              end
      `endif
      `ifdef CASE_2W16T
              for(integer j=0; j<19; j=j+1) begin        
                if(result_19_hard[j]==result_19_soft[18-j]) begin
                  result_19_pass[j]  = 1'b1;
                end else begin
                  result_19_pass[j]  = 1'b0;
                end
              end
      `endif
      `ifdef CASE_4W8T
              for(integer i=0; i<28; i=i+1) begin        
                if(result_28_hard[i]==result_28_soft[27-i]) begin
                  result_28_pass[i]  = 1'b1;
                end else begin
                  result_28_pass[i]  = 1'b0;
                end
              end
      `endif
      `ifdef CASE_4W16T
              for(integer i=0; i<53; i=i+1) begin        
                if(result_53_hard[i]==result_53_soft[52-i]) begin
                  result_53_pass[i]  = 1'b1;
                end else begin
                  result_53_pass[i]  = 1'b0;
                end
              end
      `endif
      `ifdef CASE_8W8T
              for(integer i=0; i<53; i=i+1) begin        
                if(result_53_hard[i]==result_53_soft[52-i]) begin
                  result_53_pass[i]  = 1'b1;
                end else begin
                  result_53_pass[i]  = 1'b0;
                end
              end
      `endif

      `ifdef CASE_8W4T
            if(&result_19_pass) begin
              $display("**************case_nn_8w4t*************");
              $display("******************PASS*****************");
            end else begin
              $display("**************case_nn_8w4t*************");
              $display("*****************FAILED****************");
            end
      `endif
      `ifdef CASE_2W16T
            if(&result_19_pass) begin
              $display("*************case_nn_2w16t*************");
              $display("*****************PASS******************");
            end else begin
              $display("*************case_nn_2w16t*************");
              $display("****************FAILED*****************");
            end
      `endif
      `ifdef CASE_4W8T
            if(&result_28_pass) begin
              $display("**************case_nn_4w8t*************");
              $display("******************PASS*****************");
            end else begin
              $display("**************case_nn_4w8t*************");
              $display("*****************FAILED****************");
            end
      `endif
      `ifdef CASE_4W16T
            if(&result_53_pass) begin
              $display("*************case_nn_4w16t*************");
              $display("*****************PASS******************");
            end else begin
              $display("*************case_nn_4w16t*************");
              $display("****************FAILED*****************");
            end
      `endif
      `ifdef CASE_8W8T
            if(&result_53_pass) begin
              $display("**************case_nn_8w8t*************");
              $display("******************PASS*****************");
            end else begin
              $display("**************case_nn_8w8t*************");
              $display("*****************FAILED****************");
            end
      `endif
    end
  endtask

endmodule

