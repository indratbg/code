<?php
/**
 * Connect to SSS Front office socket.
 * This class require parameter socket_fo_ip and socket_fo_port at params section of "config/main.php".
 * @author Wiyanto
 *
 */
class SocketToFront {
	private $sock;
	
	/**
	 * 
	 * @throws CHttpException 
	 */
	public function __construct()
	{
		if(($this->sock = socket_create(AF_INET, SOCK_STREAM, SOL_TCP)) === false )
		{
			$errorcode = socket_last_error();
			$errormsg = socket_strerror($errorcode);
			 
			throw new CHttpException(500,"Internal server error. Couldn't create socket: [$errorcode] $errormsg \n");
		}
		
		//Connect socket to remote server
		if(socket_connect($this->sock , Yii::app()->params['socket_fo_ip'] , Yii::app()->params['socket_fo_port']) === false)
		{
			$errorcode = socket_last_error();
			$errormsg = socket_strerror($errorcode);

			throw new CHttpException(500,"Internal server error. Couldn't connect socket: [$errorcode] $errormsg \n");
			
			
		}
	}
	
	/**
	 * Push client cash
	 * 
	 * @param String $client_cd client code nasabah yang mau di push cash ke FO
	 * @throws CHttpException
	 * @return string hasil return dari server socket. antara gagal / sukses
	 */
	public function pushClientCash($client_cd)
	{
		$return = "";
		
		if(empty($client_cd)) {
			throw new CHttpException(400,'Bad request! Client code must be supplied.');
		}
		$msg= 'CCP'.chr(9).$client_cd;
		$return = $this->sendData($msg);
		
		return $return;
	}
	
	/**
	 * Push client stock to FO
	 * 
	 * @param String $client_cd client code nasabah yang mau di push cash ke FO
	 * @param String $stock_cd kode saham.
	 * @throws CHttpException
	 * @return string hasil return dari server socket. antara gagal / sukses
	 */
	public function pushClientStock($client_cd, $stock_cd)
	{
		$return = "";
	
		if(empty($client_cd) || empty($stock_cd)) {
			throw new CHttpException(400,'Bad request! Client code and Stock code must be supplied.');
		}
	
		$msg = 'CSP'.chr(9).$client_cd.chr(9).$stock_cd;
		
		$return = $this->sendData($msg);
	
		return $return;
	}
	
	private function sendData($msg) {
		$return = "";
		//Send the message to the server
		if( socket_write ( $this->sock, $msg, strlen($msg)) === false )
		{
			$errorcode = socket_last_error();
			$errormsg = socket_strerror($errorcode);
		
			throw new CHttpException(500,"Internal server error. Could not send data: [$errorcode] $errormsg \n");
		}
		
		//Now receive reply from server
		$return = socket_read($this->sock, 2045);
		if($return === false)
		{
			$errorcode = socket_last_error();
			$errormsg = socket_strerror($errorcode);
		
			throw new CHttpException(500,"Internal server error. Could not receive data: [$errorcode] $errormsg \n");
		}
		
		return $return;
	}
	
	/**
	 * Close socket connection
	 */
	public function closeConnection()
	{
		socket_close($this->sock);
	}
}