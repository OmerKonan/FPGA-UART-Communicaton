library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc_comm is
generic (
    M : integer := 125000000 / 115200
);
port (
    -- interfaces
    clk : in std_logic;
    i_rx: in std_logic;
    o_tx : out std_logic;
    o_led : out std_logic
);
end pc_comm;

architecture rtl of pc_comm is
    signal start : std_logic := '0';
    signal data : std_logic_vector(7 downto 0) := (others => '0');
    signal led : std_logic := '0';
begin

    o_led <= led;

    -- Connect in loopback mode
    tx0 : entity work.uart_tx(rtl) generic map (M => M)
    port map (clk => clk, o_tx => o_tx,
    i_start => start, i_data => data, o_tx_done => open);

    rx0 : entity work.uart_rx(rtl) generic map (M => M)
    port map (clk => clk, i_rx => i_rx,
    o_data => data, o_ready => start);

end rtl;