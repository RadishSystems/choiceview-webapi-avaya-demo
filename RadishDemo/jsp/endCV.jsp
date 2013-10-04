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
            String dialogname = "dialog0.vxml";
            String callerId = request.getParameter("callID");
            String callId = request.getParameter("in_connectionid");
            
            int sessionID = 0;

    		try {
    			HashMap map = (HashMap)application.getAttribute("CVSHash");
   
    			if(map != null && map.containsKey(callId)){
    				
    				ChoiceViewSession CVS = (ChoiceViewSession)map.get(callId);
    				
    				com.radish.choiceview.ChoiceViewServlet.removeSession(Integer.toString(CVS.getSessionId()));
    				
    				System.out.println("Choice View Update Session status: " + CVS.updateSession()); 	
   					System.out.println("Ending Choice View Session: hashCode-" + CVS.hashCode());
   					System.out.println("Choice View Session status before endSession: " + CVS.getStatus()); 

       				if("connected".equalsIgnoreCase(CVS.getStatus())){
       					if(CVS.endSession()){
       						System.out.println("Choice View Session ended."); 
       					}else{
       						System.out.println("Could not end Choice View Session."); 
       					}
       				}
       			
       				//remove this session from the hash
       				map.remove(callId);
       				
       				//reset the attribute with the new hash
       				application.setAttribute("CVSHash", map);
        			
    			}else{
    				System.out.println("Couldn't get CVS object from the application session");
    			}
				
    		} catch (Exception e) {
    			// TODO Auto-generated catch block
    			e.printStackTrace();
    		}
            
%>
result = 'OKAY';
sessionID=<%=sessionID%>;
<%
request.getSession().invalidate();
%>