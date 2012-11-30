//@author: Martin Zrcek
//@help: Effect slowly changes the output picture. It just simply adds new picture to old one in some "speed".
//@tags:
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS: 
//		backbufferWidth, Height: Should be the resolution of final image
//		speeed: <0..2> How fast will the final image update
// --------------------------------------------------------------------------------------------------

//texture
texture Tex1 <string uiname="Texture actual";>;
sampler ActualSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex1);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
};
texture Tex2 <string uiname="Texture stored";>;
sampler StoredSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};
int backbufferWidth = 400;
int backbufferHeight = 300;
float speed = 0.1;
bool update = true;


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
    
    //transform texturecoordinates
    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    if (update) {
		float4 col = speed*tex2D(ActualSamp, In.TexCd)+tex2D(StoredSamp, In.TexCd);
	    col.rgb/=1.0+speed;
		return col;
    } else return tex2D(StoredSamp, In.TexCd);
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}

