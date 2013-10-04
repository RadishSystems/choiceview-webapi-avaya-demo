<%@ page session="true" %>
<%@ page import="java.util.*"%>
<%@ page import="java.net.*"%>
<%@ page import="java.io.*"%>
<%@ page import="java.util.Map"%>
<%@ page import="java.util.Map.Entry"%>
<%@ page import="com.radishsystems.choiceview.webapi.*" %>
<%
            /* do not want jsp content cached */
            response.setHeader("Cache-Control", "no-store");
            response.setHeader("Pragma", "no-cache");
            response.setHeader("Expires", "1");

            /* set the content type */
            response.setContentType("text/ecmascript; charset=UTF-8");

            /*
             * passed in ANI
             */
            String dialogname = "'dialog0.vxml'";
            String returnVal = "'OKAY'";
            String callerId = request.getParameter("callID");
            String callId = request.getParameter("in_connectionid");

            String menuName = request.getParameter("menuName");
            String buttonName = request.getParameter("buttonName");
            
            URL url = new URL (request.getRequestURL().toString());
            String host = url.getHost();
            String port = Integer.toString(url.getPort());
            String protocol = url.getProtocol();
            String locationExt = protocol + "://" + host + ":" + port;
            String locationLocal = protocol +  "://" + host + ":" + port + "/RadishDemo/jsp/";
            
         
            try {
            	//get the Hash so we can pull the Choice View Session out
    			HashMap map = (HashMap)application.getAttribute("CVSHash");
   
    			if(map != null && map.containsKey(callId)){
    				
    				ChoiceViewSession CVS = (ChoiceViewSession)map.get(callId);
    				 
    				if("Main_Menu".equals(menuName)){
    					
    					if("Visual_Response".equals(buttonName)){
	    					//send html to the mobile device
	        				CVS.sendUrl("http://cvnet.radishsystems.com/choiceview/samples/generic_order_status.html");
	        				dialogname = "'OrderStatus.vxml'";
    					}else if("Radish_Website".equals(buttonName)){
	    					//send html to the mobile device
	        				CVS.sendUrl("http://www.radishsystems.com");
	        				dialogname = "'RadishWebsite.vxml'";
	        				returnVal = "'DISCONNECT'";//tell the CCXML to change states to play the Goodbye message and cleanup.
    					}
    					else if("Customer_Support".equals(buttonName)){
	    					//send html to the mobile device
	        				CVS.sendUrl("http://cvnet.radishsystems.com/choiceview/samples/radish_transfer.html");
	        				System.out.println("transferSession result: " + CVS.transferSession("radish1"));
	        				dialogname = "'RadishTransfer.vxml'";
	        				returnVal = "'TRANSFER'";
    					}else{
    						//default to the main menu
    						CVS.sendUrl("http://cvnet.radishsystems.com/choiceview/ivr/openmethods_main_menu.html");
    						dialogname = "'MainMenu.vxml'";
    					}
    				}
    					
    			}else{
    				System.out.println("Couldn't get CVS object from the application session");
    			}
				
    		} catch (Exception e) {
    			// TODO Auto-generated catch block
    			e.printStackTrace();
    		}
            
%>
result = <%=returnVal%>; 
dialogname=<%=dialogname%>;
