----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:15:41 05/16/2025 
-- Design Name: 
-- Module Name:    asynchronous_fifo - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity asynchronous_fifo is
    Port ( wr_clk   : in  STD_LOGIC;
           rd_clk   : in  STD_LOGIC;
           reset    : in  STD_LOGIC;
           wr_en    : in  STD_LOGIC;
           rd_en    : in  STD_LOGIC;
           data_in  : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out : out  STD_LOGIC_VECTOR (7 downto 0);
           full     : out  STD_LOGIC;
           empty    : out  STD_LOGIC);
end asynchronous_fifo;

architecture Behavioral of asynchronous_fifo is
	constant data_width : integer := 8;
	constant addr_width : integer := 3;                 -- 3 address bits (2³ = 8)
	constant depth      : integer := 2**addr_width;
	
	type memory_array is array (0 to depth-1) of std_logic_vector(data_width-1 downto 0);
	signal memory : memory_array := (others => (others => '0'));
 	
	-- binary pointers
	signal wr_ptr_bin  		 : std_logic_vector(addr_width downto 0) := (others => '0');  
	signal rd_ptr_bin  		 : std_logic_vector(addr_width downto 0) := (others => '0');
	
	-- gray pointers
	signal wr_ptr_gray       : std_logic_vector(addr_width downto 0) := (others => '0');  
	signal rd_ptr_gray       : std_logic_vector(addr_width downto 0) := (others => '0');  
		
	  -- synchronized gray pointers across domains
	signal wr_ptr_gray_sync1 : std_logic_vector(addr_width downto 0) := (others => '0'); 
	signal wr_ptr_gray_sync2 : std_logic_vector(addr_width downto 0) := (others => '0');
	signal rd_ptr_gray_sync1 : std_logic_vector(addr_width downto 0) := (others => '0'); 
	signal rd_ptr_gray_sync2 : std_logic_vector(addr_width downto 0) := (others => '0'); 
	
	-- tracking full/empty conditions
	signal full_flag         : std_logic := '0';
	signal empty_flag        : std_logic := '1';
	
	-- utility: binary to gray
	function bin2gray(b : std_logic_vector) return std_logic_vector is
		variable g : std_logic_vector(b'range);
	begin 
		g(b'high) := b(b'high);
		for i in b'high-1 downto b'low loop
			g(i) := b(i+1) xor b(i);
		end loop;
		return g;
	end;
	
	-- utility gray to binary
	function gray2bin(g :std_logic_vector) return std_logic_vector is 
		variable b : std_logic_vector(g'range);
	begin
		b(g'high) := g(g'high);
		for i in g'high-1 downto g'low loop
			b(i) := g(i+1) xor g(i);
		end loop;
		return b;
	end;
		
begin
------------------------------------------------------------------------
-- Pointer Synchronization Across Clock Domains
------------------------------------------------------------------------
-- Sync read pointer into write clock domain
    process(wr_clk, reset)
    begin
        if reset = '1' then
            rd_ptr_gray_sync1 <= (others => '0');
            rd_ptr_gray_sync2 <= (others => '0');
        elsif rising_edge(wr_clk) then
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end if;
    end process;
	 
	 
	 -- Sync write pointer into read clock domain
    process(rd_clk, reset)
    begin
        if reset = '1' then
            wr_ptr_gray_sync1 <= (others => '0');
            wr_ptr_gray_sync2 <= (others => '0');
        elsif rising_edge(rd_clk) then
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end if;
    end process;
	 

------------------------------------------------------------------------
-- WRITE DOMAIN
------------------------------------------------------------------------
	process(wr_clk,reset)
		variable next_wr_ptr_bin : std_logic_vector(addr_width downto 0);
	begin
		if reset = '1' then
			wr_ptr_bin  		<= (others => '0');
			wr_ptr_gray 		<= (others => '0');
			--rd_ptr_gray_sync1 <= (others => '0');
			--rd_ptr_gray_sync2 <= (others => '0');
			full_flag         <= '0';
		elsif (rising_edge(wr_clk)) then
			--synchronize read pointer
			--rd_ptr_gray_sync1 <= rd_ptr_gray;
			--rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
			
			-- write if not full
			if (wr_en = '1' and full_flag = '0') then 
				-- write data into memory
				memory(to_integer(unsigned(wr_ptr_bin(addr_width-1 downto 0)))) <= data_in;
				
				-- Compute the next binary write pointer using a variable
				next_wr_ptr_bin := std_logic_vector(unsigned(wr_ptr_bin)+1);
				
				-- Update binary and Gray-coded write pointers
				wr_ptr_bin  <= next_wr_ptr_bin;
				wr_ptr_gray <= bin2gray(next_wr_ptr_bin);
			
			end if;
			
			-- full condition
			if ((wr_ptr_gray(addr_width downto addr_width-1) = not rd_ptr_gray_sync2(addr_width downto addr_width-1)) and
				(wr_ptr_gray(addr_width-2 downto 0) = rd_ptr_gray_sync2(addr_width-2 downto 0))) then 
					full_flag <= '1';
			else 
					full_flag <= '0';
			end if;
		
		end if;
	end process;

------------------------------------------------------------------------
-- READ DOMAIN
------------------------------------------------------------------------
	process(rd_clk,reset)
		variable next_rd_ptr_bin: std_logic_vector(addr_width downto 0);
	begin
		if reset = '1' then
			rd_ptr_bin  		<= (others => '0');
			rd_ptr_gray 		<= (others => '0');
			--wr_ptr_gray_sync1 <= (others => '0');
			--wr_ptr_gray_sync2 <= (others => '0');
			empty_flag        <= '1';
			
		elsif (rising_edge(rd_clk)) then
			--synchronize write pointer
			--wr_ptr_gray_sync1 <= wr_ptr_gray;
			--wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
			
			-- read if not empty
			if (rd_en = '1' and empty_flag = '0') then 
				data_out    <= memory(to_integer(unsigned(rd_ptr_bin(addr_width-1 downto 0))));
				
			-- safely compute next pointer
				next_rd_ptr_bin  := std_logic_vector(unsigned(rd_ptr_bin) + 1);
			
			-- update binary and Gray-coded read pointers
				rd_ptr_bin  <= next_rd_ptr_bin;
				rd_ptr_gray <= bin2gray(next_rd_ptr_bin);
			
			end if;
			
			-- empty condition
			if (gray2bin(rd_ptr_gray) = gray2bin(wr_ptr_gray_sync2))  then 
					empty_flag <= '1';
			else 
					empty_flag <= '0';
			end if;
		end if;
	end process;
	
------------------------------------------------------------------------
-- OUTPUT FLAGS
------------------------------------------------------------------------
    full  <= full_flag;
    empty <= empty_flag;
	 
end Behavioral;

