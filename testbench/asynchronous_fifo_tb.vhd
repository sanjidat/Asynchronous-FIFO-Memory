--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:02:42 05/16/2025
-- Design Name:   
-- Module Name:   /home/ise/vm/asynchronous_fifo/asynchronous_fifo_tb.vhd
-- Project Name:  asynchronous_fifo
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: asynchronous_fifo
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY asynchronous_fifo_tb IS
END asynchronous_fifo_tb;
 
ARCHITECTURE behavior OF asynchronous_fifo_tb IS 

	constant data_width : integer := 8;
   constant addr_width : integer := 3;
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT asynchronous_fifo
    PORT(
         wr_clk : IN  std_logic;
         rd_clk : IN  std_logic;
         reset : IN  std_logic;
         wr_en : IN  std_logic;
         rd_en : IN  std_logic;
         data_in : IN  std_logic_vector(7 downto 0);
         data_out : OUT  std_logic_vector(7 downto 0);
         full : OUT  std_logic;
         empty : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal wr_clk : std_logic := '0';
   signal rd_clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal wr_en : std_logic := '0';
   signal rd_en : std_logic := '0';
   signal data_in : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal data_out : std_logic_vector(7 downto 0);
   signal full : std_logic;
   signal empty : std_logic;

   -- Clock period definitions
   constant wr_clk_period : time := 20 ns;
   constant rd_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: asynchronous_fifo PORT MAP (
          wr_clk => wr_clk,
          rd_clk => rd_clk,
          reset => reset,
          wr_en => wr_en,
          rd_en => rd_en,
          data_in => data_in,
          data_out => data_out,
          full => full,
          empty => empty
        );

   -- Clock process definitions
   wr_clk_process :process
   begin
		wr_clk <= '0';
		wait for wr_clk_period/2;
		wr_clk <= '1';
		wait for wr_clk_period/2;
   end process;
 
   rd_clk_process :process
   begin
		rd_clk <= '0';
		wait for rd_clk_period/2;
		rd_clk <= '1';
		wait for rd_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- insert stimulus here 
		-- reset
		wait for 20 ns;
		reset <= '1';
		wait for 50 ns;
		reset <= '0';
		
		-- write some data
		wait for 50 ns;
		for i in 0 to 7 loop
			wait until rising_edge(wr_clk);
			wr_en <= '1';
			data_in <= std_logic_vector(to_unsigned(10 + i, data_width));
		end loop;
		wait until rising_edge(wr_clk);
			wr_en <= '0';
		
		
		-- read some data
		wait for 100 ns; -- Delay for sync
		for i in 0 to 7 loop
			wait until rising_edge(rd_clk);
			rd_en <= '1';
		end loop;
		wait until rising_edge(rd_clk);
			rd_en <= '0';
		wait for 70 ns;
      wait;
   end process;

END;
