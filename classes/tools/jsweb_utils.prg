#INCLUDE json-fox.h

* Version 1.3.4

define class WebUtils as custom

	oUrlParts = .null.

	function ourlparts_access()

		if isnull(this.oUrlParts)
			this.oUrlParts = createobject("Empty")
			addproperty(this.oUrlParts, "Protocol", "")
			addproperty(this.oUrlParts, "Host", "")
			addproperty(this.oUrlParts, "Path", "")
			addproperty(this.oUrlParts, "QueryString", "")
			addproperty(this.oUrlParts, "Fragment", "")
		endif
		return this.oUrlParts

	endfunc

	function UrlEncode(tcString)
		local lcEncoded, lnChar, lcChar, lcHex

		lcEncoded = ""
		for lnChar = 1 to len(tcString)
			lcChar = substr(tcString, lnChar, 1)
			do case
				case lcChar $ "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
					lcEncoded = lcEncoded + lcChar
				otherwise
					lcHex = transform(asc(lcChar), "@0")
					lcEncoded = lcEncoded + "%" + lcHex
			endcase
		endfor

		return lcEncoded
	endfunc

	function UrlDecode(tcString)
		local lcDecoded, lnChar, lcChar, lcHex

		lcDecoded = ""
		lnChar = 1
		do while lnChar <= len(tcString)
			lcChar = substr(tcString, lnChar, 1)
			if lcChar == "%"
				lcHex = substr(tcString, lnChar + 1, 2)
				lcDecoded = lcDecoded + chr(val("0x" + lcHex))
				lnChar = lnChar + 2
			else
				lcDecoded = lcDecoded + lcChar
			endif
			lnChar = lnChar + 1
		enddo

		return lcDecoded
	endfunc

	function ParseUrl(tcUrl)
		local loUrlParts, lcProtocol, lcHost, lcPath, lcQueryString, lcFragment, lnPos

		loUrlParts = this.oUrlParts

		* Extract protocol
		lnPos = at("://", tcUrl)
		if lnPos > 0
			loUrlParts.Protocol = left(tcUrl, lnPos - 1)
			tcUrl = substr(tcUrl, lnPos + 3)
		endif

		* Extract fragment
		lnPos = at("#", tcUrl)
		if lnPos > 0
			loUrlParts.Fragment = substr(tcUrl, lnPos + 1)
			tcUrl = left(tcUrl, lnPos - 1)
		endif

		* Extract query string
		lnPos = at("?", tcUrl)
		if lnPos > 0
			loUrlParts.QueryString = substr(tcUrl, lnPos + 1)
			tcUrl = left(tcUrl, lnPos - 1)
		endif

		* Extract host and path
		lnPos = at("/", tcUrl)
		if lnPos > 0
			loUrlParts.host = left(tcUrl, lnPos - 1)
			loUrlParts.path = substr(tcUrl, lnPos)
		else
			loUrlParts.host = tcUrl
		endif

		return loUrlParts
	endfunc

	function StringifyUrl(toUrlParts)
		local lcUrl

		toUrlParts = iif(vartype(toUrlParts) == "O", toUrlParts, this.oUrlParts)

		lcUrl = ""

		* Add protocol
		if not empty(toUrlParts.Protocol)
			lcUrl = toUrlParts.Protocol + "://"
		endif

		* Add host
		lcUrl = lcUrl + toUrlParts.host

		* Add path
		if not empty(toUrlParts.path)
			lcUrl = lcUrl + toUrlParts.path
		endif

		* Add query string
		if not empty(toUrlParts.QueryString)
			lcUrl = lcUrl + "?" + toUrlParts.QueryString
		endif

		* Add fragment
		if not empty(toUrlParts.Fragment)
			lcUrl = lcUrl + "#" + toUrlParts.Fragment
		endif

		return lcUrl
	ENDFUNC
	
enddefine
