DEFINE VARIABLE vcHost     AS CHARACTER    INITIAL "localhost"   NO-UNDO.
DEFINE VARIABLE vhSocket   AS HANDLE                             NO-UNDO.
 
DEFINE INPUT PARAMETER pchFormData AS CHARACTER  NO-UNDO.
DEFINE OUTPUT PARAMETER opServerResponseData AS CHARACTER  NO-UNDO.
 
CREATE SOCKET vhSocket.
vhSocket:CONNECT('-H www.google.com -S 443 -ssl' ) NO-ERROR.
    
IF vhSocket:CONNECTED() = FALSE THEN
DO:
    MESSAGE "Connection failure" VIEW-AS ALERT-BOX.
    
    MESSAGE ERROR-STATUS:GET-MESSAGE(1) VIEW-AS ALERT-BOX.
    RETURN.
END.
ELSE
   MESSAGE "Connect"
       VIEW-AS ALERT-BOX.
 
vhSocket:SET-READ-RESPONSE-PROCEDURE('getResponse').


RUN PostRequest (INPUT "/recaptcha/api/siteverify", 
                 INPUT pchFormData).
 
WAIT-FOR READ-RESPONSE OF vhSocket. 

vhSocket:DISCONNECT() NO-ERROR.

DELETE OBJECT vhSocket.

RETURN.
 
PROCEDURE getResponse:
    DEFINE VARIABLE vcWebResp    AS CHARACTER        NO-UNDO.
    DEFINE VARIABLE lSucess      AS LOGICAL          NO-UNDO.
    DEFINE VARIABLE mResponse    AS MEMPTR           NO-UNDO.
    
    IF vhSocket:CONNECTED() = FALSE THEN do:
        MESSAGE 'Not Connected' VIEW-AS ALERT-BOX.
        RETURN.
    END.
    lSucess = TRUE.
        
    DO WHILE vhSocket:GET-BYTES-AVAILABLE() > 0:
            
         SET-SIZE(mResponse) = vhSocket:GET-BYTES-AVAILABLE() + 1.
         SET-BYTE-ORDER(mResponse) = BIG-ENDIAN.
         vhSocket:READ(mResponse,1,1,vhSocket:GET-BYTES-AVAILABLE()).
         vcWebResp = vcWebResp + GET-STRING(mResponse,1).
    END.
    
    /** Strip away the HTTP headers. **/
    vcWebResp = REPLACE(vcWebResp, "~r~n", "~r").
    
    vcWebResp = SUBSTRING(vcWebResp, INDEX(vcWebResp, "~r~r") + 2).
    
    opServerResponseData = vcWebResp.
    
END.


PROCEDURE PostRequest:
    DEFINE VARIABLE vcRequest      AS CHARACTER.
    DEFINE VARIABLE mRequest       AS MEMPTR.
    DEFINE INPUT PARAMETER postUrl AS CHAR. 
    /* URL that will send the data. It must be all the path after the server.  IE:/scripts/cgiip.exe/WService=wsbroker1/myApp.htm */
    DEFINE INPUT PARAMETER postData AS CHAR.
    /* Parameters to be sent in the format paramName=value&paramName=value&paramName=value */
    vcRequest =
        'POST ' +
        postUrl +
        ' HTTP/1.0~r~n' +
        'Content-Type: application/x-www-form-urlencoded~r~n' +
        'Content-Length:' + string(LENGTH(postData)) +
        '~r~n' + '~r~n' +
        postData + '~r~n'.
 
    SET-SIZE(mRequest)            = 0.
    SET-SIZE(mRequest)            = LENGTH(vcRequest) + 1.
    SET-BYTE-ORDER(mRequest)      = BIG-ENDIAN.
    PUT-STRING(mRequest,1)        = vcRequest .
 
    vhSocket:WRITE(mRequest, 1, LENGTH(vcRequest)).
END PROCEDURE.
