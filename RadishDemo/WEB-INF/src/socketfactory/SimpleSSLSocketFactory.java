package socketfactory;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.URL;
import java.net.UnknownHostException;
import java.security.KeyStore;

import javax.net.SocketFactory;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;

import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.commons.httpclient.params.HttpConnectionParams;
import org.apache.commons.httpclient.protocol.SecureProtocolSocketFactory;

/*
 * This class was derived from various pieces of code in the httpclient source.  None
 * of the examples actually work or contain all the classes they reference.  This class
 * does the minimum we need to talk to the VP MPP allowing us to send an event back
 * to the CCXML session, once we receive one.   This is based on the commons httpclient
 * version 3.0.1 .
 */
public class SimpleSSLSocketFactory implements SecureProtocolSocketFactory {
	private URL keystoreUrl = null;
	private String keystorePassword = null;
	private SSLContext sslcontext = null;

	private SSLContext createSSLContext() {
		try {
			System.out.println("Create context");
			KeyStore keystore = KeyStore.getInstance("jks");
			InputStream is = null;
			try {
				is = keystoreUrl.openStream();
				keystore.load(is, keystorePassword.toCharArray());
			} finally {
				if (is != null)
					is.close();
			}
			KeyManagerFactory kmfactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
			kmfactory.init(keystore, keystorePassword.toCharArray());
			KeyManager[] keymanagers = kmfactory.getKeyManagers();
			SSLContext sslcontext = SSLContext.getInstance("TLS");

			TrustManagerFactory tmfactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
			tmfactory.init(keystore);
			TrustManager[] trustmanagers = tmfactory.getTrustManagers();
			sslcontext.init(keymanagers, trustmanagers, null);
			return sslcontext;
		} catch (Exception ex) {
			// this is not the way a sane exception handling should be done
			// but for our simple HTTP testing framework this will suffice
			System.out.println(ex + ":" + ex.getMessage());
			throw new IllegalStateException(ex.getMessage());
		}

	}

	private SSLContext getSSLContext() {
		if (sslcontext == null) {
			sslcontext = createSSLContext();
		}
		return sslcontext;
	}

	public SimpleSSLSocketFactory(URL keystore, String keystorePassword) {
		super();
		this.keystoreUrl = keystore;
		this.keystorePassword = keystorePassword;
		System.out.println("simple ssl factory");
	}

	/**
	 * Attempts to get a new socket connection to the given host within the
	 * given time limit.
	 * <p>
	 * To circumvent the limitations of older JREs that do not support connect
	 * timeout a controller thread is executed. The controller thread attempts
	 * to create a new socket within the given limit of time. If socket
	 * constructor does not return until the timeout expires, the controller
	 * terminates and throws an {@link ConnectTimeoutException}
	 * </p>
	 * 
	 * @param host
	 *            the host name/IP
	 * @param port
	 *            the port on the host
	 * @param clientHost
	 *            the local host name/IP to bind the socket to
	 * @param clientPort
	 *            the port on the local machine
	 * @param params
	 *            {@link HttpConnectionParams Http connection parameters}
	 * 
	 * @return Socket a new socket
	 * 
	 * @throws IOException
	 *             if an I/O error occurs while creating the socket
	 * @throws UnknownHostException
	 *             if the IP address of the host cannot be determined
	 */
	public Socket createSocket(final String host, final int port, final InetAddress localAddress, final int localPort,
			final HttpConnectionParams params) throws IOException, UnknownHostException, ConnectTimeoutException {
		if (params == null) {
			throw new IllegalArgumentException("Parameters may not be null");
		}
		System.out.println("create socket 0");
		int timeout = params.getConnectionTimeout();
		SocketFactory socketfactory = getSSLContext().getSocketFactory();
		if (timeout == 0) {
			return socketfactory.createSocket(host, port, localAddress, localPort);
		} else {
			Socket socket = socketfactory.createSocket();
			SocketAddress localaddr = new InetSocketAddress(localAddress, localPort);
			SocketAddress remoteaddr = new InetSocketAddress(host, port);
			socket.bind(localaddr);
			socket.connect(remoteaddr, timeout);
			return socket;
		}
	}

	/**
	 * @see SecureProtocolSocketFactory#createSocket(java.lang.String,int,java.net.InetAddress,int)
	 */
	public Socket createSocket(String host, int port, InetAddress clientHost, int clientPort) throws IOException,
			UnknownHostException {
		System.out.println("create socket 1");
		return getSSLContext().getSocketFactory().createSocket(host, port, clientHost, clientPort);
	}

	/**
	 * @see SecureProtocolSocketFactory#createSocket(java.lang.String,int)
	 */
	public Socket createSocket(String host, int port) throws IOException, UnknownHostException {
		System.out.println("create socket 2");
		return getSSLContext().getSocketFactory().createSocket(host, port);
	}

	/**
	 * @see SecureProtocolSocketFactory#createSocket(java.net.Socket,java.lang.String,int,boolean)
	 */
	public Socket createSocket(Socket socket, String host, int port, boolean autoClose) throws IOException, UnknownHostException {
		System.out.println("create socket 3");
		return getSSLContext().getSocketFactory().createSocket(socket, host, port, autoClose);
	}
}
