//@author: Martin Zrcek
//@help: shows picture where is a difference between two images .. it's a green screen
//@tags:
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//texture
texture Tex1 <string uiname="Stored Texture";>;
sampler StoredSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex1);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};
//texture
texture Tex2 <string uiname="Camera Texture";>;
sampler CameraSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
};
float passLevel = 0.1;
float crossSpan = 1;
float softness = .05;
int backbufferWidth = 400;
int backbufferHeight = 300;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //declare output struct
    vs2ps Out;

    //transform position
    Out.Pos = float4(PosO.x*2.0-(1.0/backbufferWidth), PosO.y*2.0+(1.0/backbufferHeight), 0.0, 1.0);
    //Out.Pos = float4(PosO.x*2.0, PosO.y*2.0, 0.0, 1.0);
    
    //transform texturecoordinates
    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    float4 col0 = tex2D(StoredSamp, In.TexCd);
    float4 col1 = tex2D(CameraSamp, In.TexCd);
	float4 col = col1;
	if (length(col0-col1)>passLevel) col=col1;
	else col.a=0;
    return col;
}
float4 PScross(vs2ps In): COLOR
{
	float4 col = tex2D(CameraSamp, In.TexCd);
	float2 cSpanX = float2(crossSpan / backbufferWidth,0.0);
	float2 cSpanY = float2(0.0,crossSpan / backbufferHeight);
	int stencil=0;
    if(length( tex2D(StoredSamp, In.TexCd) - tex2D(CameraSamp, In.TexCd) )>passLevel) stencil+=2;
    if(length( tex2D(StoredSamp, In.TexCd+cSpanX) - tex2D(CameraSamp, In.TexCd+cSpanX) )>passLevel) stencil++;
    if(length( tex2D(StoredSamp, In.TexCd+cSpanY) - tex2D(CameraSamp, In.TexCd+cSpanY) )>passLevel) stencil++;
    if(length( tex2D(StoredSamp, In.TexCd-cSpanX) - tex2D(CameraSamp, In.TexCd-cSpanX) )>passLevel) stencil++;
    if(length( tex2D(StoredSamp, In.TexCd-cSpanY) - tex2D(CameraSamp, In.TexCd-cSpanY) )>passLevel) stencil++;
	if (stencil>2) col.a=1.0;
	else col.a=.0;
    return col;
}
// looks at a place and sums distances form 5 positions in X
float examine (float2 place) {
	float mult = 0.4;
	float2 XSpan1 = float2(mult*crossSpan / backbufferWidth,mult*crossSpan / backbufferHeight);
	float2 XSpan2 = float2(-mult*crossSpan / backbufferWidth,mult*crossSpan / backbufferHeight);
	float diffSum = 0;
	diffSum+= length( tex2D(StoredSamp, place).xyz - tex2D(CameraSamp, place).xyz );
	diffSum+= length( tex2D(StoredSamp, place+XSpan1).xyz - tex2D(CameraSamp, place+XSpan1).xyz );
	diffSum+= length( tex2D(StoredSamp, place+XSpan2).xyz - tex2D(CameraSamp, place+XSpan2).xyz );
	diffSum+= length( tex2D(StoredSamp, place-XSpan1).xyz - tex2D(CameraSamp, place-XSpan1).xyz );
	diffSum+= length( tex2D(StoredSamp, place-XSpan2).xyz - tex2D(CameraSamp, place-XSpan2).xyz );
	return diffSum*.2;
}
float4 PSfloatCross(vs2ps In): COLOR
{
	float4 col = tex2D(CameraSamp, In.TexCd);
	float2 cSpanX = float2(crossSpan / backbufferWidth,0.0);
	float2 cSpanY = float2(0.0,crossSpan / backbufferHeight);
	float sum= length( tex2D(StoredSamp, In.TexCd) - tex2D(CameraSamp, In.TexCd) );
	sum+= examine(In.TexCd+cSpanX);
	sum+= examine(In.TexCd+cSpanY);
	sum+= examine(In.TexCd-cSpanX);
	sum+= examine(In.TexCd-cSpanY);
	sum*=.2;
	if (sum>=passLevel+softness) col.a=1.0;
	else if (sum<=passLevel) col.a=0.0;
	else col.a = (sum-passLevel)/softness;
	//col.a=1;
    return col;
}
float4 PSfloatCrossLOD(vs2ps In): COLOR
{
	float4 col = tex2Dlod(CameraSamp, float4(In.TexCd,10.0,0));
	float2 cSpanX = float2(crossSpan / backbufferWidth,0.0);
	float2 cSpanY = float2(0.0,crossSpan / backbufferHeight);
	float sum= length( tex2D(StoredSamp, In.TexCd) - tex2D(CameraSamp, In.TexCd) );
	sum+= examine(In.TexCd+cSpanX);
	sum+= examine(In.TexCd+cSpanY);
	sum+= examine(In.TexCd-cSpanX);
	sum+= examine(In.TexCd-cSpanY);
	sum*=.2;
	if (sum>=passLevel+softness) col.a=1.0;
	else if (sum<=passLevel) col.a=0.0;
	else col.a = (sum-passLevel)/softness;
	//col.a=1;
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleHighPass
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}
technique TCrossHighPass
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PScross();
    }
}
technique TCrossFloatPass
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PSfloatCross();
    }
}
technique TCrossFloatLODPass
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PSfloatCrossLOD();
    }
}