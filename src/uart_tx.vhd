library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity uart_tx is
  generic (
    M : integer := 125000000 / 115200     -- Needs to be set correctly
    );
  port (
  -- interfaces
    clk : in  std_logic;
    o_tx : out std_logic;
  -- control signals
    i_data : in  std_logic_vector(7 downto 0);
    i_start : in  std_logic;
    o_tx_done : out std_logic
    );
end uart_tx;

architecture rtl of uart_tx is
    signal cnt : unsigned(31 downto 0) := to_unsigned(M-1, 32);
    signal cntrst, cntdone : std_logic := '1';
    signal dbuf : std_logic_vector(7 downto 0) := (others=>'0');
begin    
    -- counter
    process(clk) is 
    begin
        if rising_edge(clk) then
            if cntrst = '1' then
                cnt <= to_unsigned(M-1, 32);
                cntdone <= '0';
            else
                if cnt = 0 then
                    cnt <= to_unsigned(M-1, 32);
                else
                    cnt <= cnt - 1;
                end if;
            end if;
        end if;
    end process;
                
   -- state machine
    process(clk) is
        type state_type is (s0, s1, s2, s3, s4);
        variable state : state_type := s0;
        variable dcnt : integer := 0;
        variable par : std_logic := '0';
    begin
        if rising_edge(clk) then
            -- by default enable counter
            cntrst <= '0';
            -- by default disable done signal
            o_tx_done <= '0';

            case state is 
                -- idle
                when s0 =>
                o_tx <= '1'; -- idle tx value
                cntrst <= '1'; -- only reset counter here
                    if i_start = '1' then
                        state := s1;
                        dbuf <= i_data; -- latch
                        cntrst <= '0'; -- enable counter
                    end if;
                -- start
                when s1 =>
                    o_tx <= '0'; -- start tx value
                    if cntdone = '1' then
                        state := s2;
                    end if;
                -- data
                when s2 =>
                    o_tx <= dbuf(0);
                    if cntdone = '1' then
                        par := par xor dbuf(0);
                        dcnt := dcnt + 1;
                        if dcnt = 8 then
                            state := s3;
                            dcnt := 0;
                        else
                            dbuf <= '0' & dbuf(dbuf'left downto 1);
                        end if;
                    end if;
                -- parity
                when s3 =>
                    if par = '1' then
                        o_tx <= '0';
                    else
                        o_tx <= '1';
                    end if;

                    if cntdone = '1' then
                        state :=  s4;
                    end if;
                -- stop
                when s4 =>
                    o_tx <= '1';
                    if cntdone = '1' then
                        state := s0;
                        o_tx_done <= '1';
                    end if;
            end case;
        end if;
    end process;
end rtl;

