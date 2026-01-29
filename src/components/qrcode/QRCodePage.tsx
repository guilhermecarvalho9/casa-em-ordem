import { useState, useMemo } from 'react';
import { useApp } from '@/contexts/AppContext';
import { QRCodeSVG } from 'qrcode.react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Wifi, 
  BookOpen, 
  MapPin, 
  Phone, 
  Home, 
  Download, 
  QrCode,
  ExternalLink,
  Copy,
  Check
} from 'lucide-react';
import { toast } from 'sonner';

interface HouseInfo {
  address: string;
  emergencyPhone: string;
  adminName: string;
}

export function QRCodePage() {
  const { t, rules, passwords, language } = useApp();
  const [copied, setCopied] = useState(false);
  const [houseInfo, setHouseInfo] = useState<HouseInfo>({
    address: '',
    emergencyPhone: '',
    adminName: '',
  });

  const wifiPassword = passwords.find(p => p.category === 'wifi');

  // Generate WiFi QR code string (standard format)
  const wifiQRString = useMemo(() => {
    if (!wifiPassword) return '';
    return `WIFI:T:WPA;S:${wifiPassword.name};P:${wifiPassword.value};;`;
  }, [wifiPassword]);

  // Generate rules-only QR data (plain text format for readability)
  const rulesQRData = useMemo(() => {
    if (rules.length === 0) return '';
    const header = language === 'pt' ? '📋 REGRAS DA CASA 📋\n\n' : '📋 HOUSE RULES 📋\n\n';
    const rulesText = rules.map((r, i) => `${i + 1}. ${r.title}\n   ${r.description}`).join('\n\n');
    return header + rulesText;
  }, [rules, language]);

  // Generate combined info for QR code
  const combinedQRData = useMemo(() => {
    const rulesText = rules.map((r, i) => `${i + 1}. ${r.title}: ${r.description}`).join('\n');
    
    const data = {
      house: {
        address: houseInfo.address || (language === 'pt' ? 'Não informado' : 'Not provided'),
        emergency: houseInfo.emergencyPhone || (language === 'pt' ? 'Não informado' : 'Not provided'),
        admin: houseInfo.adminName || (language === 'pt' ? 'Não informado' : 'Not provided'),
      },
      wifi: wifiPassword ? {
        name: wifiPassword.name,
        password: wifiPassword.value,
      } : null,
      rules: rulesText,
      markets: `https://www.google.com/maps/search/supermercado+mercado/@${houseInfo.address ? encodeURIComponent(houseInfo.address) : ''}`,
    };
    
    return JSON.stringify(data, null, 0);
  }, [rules, wifiPassword, houseInfo, language]);

  // Google Maps search for nearby markets
  const marketsUrl = useMemo(() => {
    const query = language === 'pt' ? 'supermercado mercado' : 'supermarket grocery store';
    return `https://www.google.com/maps/search/${encodeURIComponent(query)}/`;
  }, [language]);

  const handleCopyWifi = () => {
    if (wifiPassword) {
      navigator.clipboard.writeText(wifiPassword.value);
      setCopied(true);
      toast.success(language === 'pt' ? 'Senha copiada!' : 'Password copied!');
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleDownloadQR = (elementId: string, filename: string) => {
    const svg = document.getElementById(elementId);
    if (svg) {
      const svgData = new XMLSerializer().serializeToString(svg);
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      const img = new Image();
      img.onload = () => {
        canvas.width = img.width;
        canvas.height = img.height;
        ctx?.drawImage(img, 0, 0);
        const pngFile = canvas.toDataURL('image/png');
        const downloadLink = document.createElement('a');
        downloadLink.download = filename;
        downloadLink.href = pngFile;
        downloadLink.click();
      };
      img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(svgData)));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
          <QrCode className="w-6 h-6 text-primary-foreground" />
        </div>
        <div>
          <h1 className="text-3xl font-display font-bold">
            {language === 'pt' ? 'QR Code da Casa' : 'House QR Code'}
          </h1>
          <p className="text-muted-foreground text-sm">
            {language === 'pt' 
              ? 'Compartilhe informações da casa facilmente' 
              : 'Share house information easily'}
          </p>
        </div>
      </div>

      <Tabs defaultValue="combined" className="space-y-4">
        <TabsList className="grid w-full grid-cols-4 lg:w-auto lg:inline-flex">
          <TabsTrigger value="combined" className="gap-2">
            <Home className="w-4 h-4" />
            {language === 'pt' ? 'Completo' : 'Complete'}
          </TabsTrigger>
          <TabsTrigger value="rules" className="gap-2">
            <BookOpen className="w-4 h-4" />
            {language === 'pt' ? 'Regras' : 'Rules'}
          </TabsTrigger>
          <TabsTrigger value="wifi" className="gap-2">
            <Wifi className="w-4 h-4" />
            WiFi
          </TabsTrigger>
          <TabsTrigger value="markets" className="gap-2">
            <MapPin className="w-4 h-4" />
            {language === 'pt' ? 'Mercados' : 'Markets'}
          </TabsTrigger>
        </TabsList>

        {/* Combined QR Code Tab */}
        <TabsContent value="combined" className="space-y-4">
          <div className="grid lg:grid-cols-2 gap-6">
            {/* House Info Form */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 font-display">
                  <Phone className="w-5 h-5 text-primary" />
                  {language === 'pt' ? 'Informações de Contato' : 'Contact Information'}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>{language === 'pt' ? 'Endereço' : 'Address'}</Label>
                  <Input
                    placeholder={language === 'pt' ? 'Rua, número, cidade' : 'Street, number, city'}
                    value={houseInfo.address}
                    onChange={(e) => setHouseInfo(prev => ({ ...prev, address: e.target.value }))}
                    className="input-field"
                  />
                </div>
                <div className="space-y-2">
                  <Label>{language === 'pt' ? 'Telefone de Emergência' : 'Emergency Phone'}</Label>
                  <Input
                    placeholder={language === 'pt' ? '(11) 99999-9999' : '+1 555-0123'}
                    value={houseInfo.emergencyPhone}
                    onChange={(e) => setHouseInfo(prev => ({ ...prev, emergencyPhone: e.target.value }))}
                    className="input-field"
                  />
                </div>
                <div className="space-y-2">
                  <Label>{language === 'pt' ? 'Nome do Administrador' : 'Admin Name'}</Label>
                  <Input
                    placeholder={language === 'pt' ? 'Nome do responsável' : 'Person in charge'}
                    value={houseInfo.adminName}
                    onChange={(e) => setHouseInfo(prev => ({ ...prev, adminName: e.target.value }))}
                    className="input-field"
                  />
                </div>
              </CardContent>
            </Card>

            {/* QR Code Display */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 font-display">
                  <QrCode className="w-5 h-5 text-primary" />
                  {language === 'pt' ? 'QR Code Combinado' : 'Combined QR Code'}
                </CardTitle>
              </CardHeader>
              <CardContent className="flex flex-col items-center gap-4">
                <div className="bg-white p-4 rounded-2xl shadow-lg">
                  <QRCodeSVG
                    id="combined-qr"
                    value={combinedQRData}
                    size={200}
                    level="M"
                    includeMargin
                  />
                </div>
                <p className="text-sm text-muted-foreground text-center">
                  {language === 'pt' 
                    ? 'Contém: WiFi, Regras, Contatos e Link para Mercados' 
                    : 'Contains: WiFi, Rules, Contacts and Markets Link'}
                </p>
                <Button 
                  onClick={() => handleDownloadQR('combined-qr', 'casa-qrcode.png')}
                  className="btn-gradient rounded-xl gap-2"
                >
                  <Download className="w-4 h-4" />
                  {language === 'pt' ? 'Baixar QR Code' : 'Download QR Code'}
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Rules Preview */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 font-display">
                <BookOpen className="w-5 h-5 text-primary" />
                {language === 'pt' ? 'Regras Incluídas no QR' : 'Rules Included in QR'}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {rules.length > 0 ? (
                <div className="grid sm:grid-cols-2 gap-3">
                  {rules.map((rule, index) => (
                    <div key={rule.id} className="flex gap-3 p-3 rounded-xl bg-muted/50">
                      <span className="w-6 h-6 rounded-full bg-primary/10 text-primary flex items-center justify-center text-sm font-medium shrink-0">
                        {index + 1}
                      </span>
                      <div>
                        <p className="font-medium text-sm">{rule.title}</p>
                        <p className="text-xs text-muted-foreground">{rule.description}</p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-muted-foreground text-center py-4">
                  {language === 'pt' ? 'Nenhuma regra cadastrada' : 'No rules registered'}
                </p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Rules Only QR Code Tab */}
        <TabsContent value="rules" className="space-y-4">
          <div className="grid lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 font-display">
                  <BookOpen className="w-5 h-5 text-primary" />
                  {language === 'pt' ? 'QR Code das Regras' : 'Rules QR Code'}
                </CardTitle>
              </CardHeader>
              <CardContent className="flex flex-col items-center gap-4">
                {rules.length > 0 ? (
                  <>
                    <div className="bg-white p-4 rounded-2xl shadow-lg">
                      <QRCodeSVG
                        id="rules-qr"
                        value={rulesQRData}
                        size={200}
                        level="L"
                        includeMargin
                      />
                    </div>
                    <p className="text-sm text-muted-foreground text-center">
                      {language === 'pt' 
                        ? 'Escaneie para ver as regras da casa' 
                        : 'Scan to see house rules'}
                    </p>
                    <Button 
                      onClick={() => handleDownloadQR('rules-qr', 'regras-qrcode.png')}
                      className="btn-gradient rounded-xl gap-2"
                    >
                      <Download className="w-4 h-4" />
                      {language === 'pt' ? 'Baixar QR Code' : 'Download QR Code'}
                    </Button>
                  </>
                ) : (
                  <div className="text-center py-8">
                    <BookOpen className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
                    <p className="text-muted-foreground">
                      {language === 'pt' 
                        ? 'Nenhuma regra cadastrada. Adicione em Regras.' 
                        : 'No rules registered. Add one in Rules.'}
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Rules Preview */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 font-display">
                  <BookOpen className="w-5 h-5 text-primary" />
                  {language === 'pt' ? 'Regras no QR Code' : 'Rules in QR Code'}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {rules.map((rule, index) => (
                  <div key={rule.id} className="flex gap-3 p-3 rounded-xl bg-muted/50">
                    <span className="w-6 h-6 rounded-full bg-primary/10 text-primary flex items-center justify-center text-sm font-medium shrink-0">
                      {index + 1}
                    </span>
                    <div>
                      <p className="font-medium text-sm">{rule.title}</p>
                      <p className="text-xs text-muted-foreground">{rule.description}</p>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* WiFi QR Code Tab */}
        <TabsContent value="wifi" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 font-display">
                <Wifi className="w-5 h-5 text-primary" />
                {language === 'pt' ? 'QR Code WiFi' : 'WiFi QR Code'}
              </CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col items-center gap-4">
              {wifiPassword ? (
                <>
                  <div className="bg-white p-4 rounded-2xl shadow-lg">
                    <QRCodeSVG
                      id="wifi-qr"
                      value={wifiQRString}
                      size={200}
                      level="M"
                      includeMargin
                    />
                  </div>
                  <div className="text-center space-y-2">
                    <p className="font-medium">{wifiPassword.name}</p>
                    <div className="flex items-center gap-2">
                      <code className="px-3 py-1 bg-muted rounded-lg text-sm">
                        {wifiPassword.value}
                      </code>
                      <Button 
                        variant="ghost" 
                        size="icon"
                        onClick={handleCopyWifi}
                        className="h-8 w-8"
                      >
                        {copied ? <Check className="w-4 h-4 text-green-500" /> : <Copy className="w-4 h-4" />}
                      </Button>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {language === 'pt' 
                        ? 'Escaneie para conectar automaticamente' 
                        : 'Scan to connect automatically'}
                    </p>
                  </div>
                  <Button 
                    onClick={() => handleDownloadQR('wifi-qr', 'wifi-qrcode.png')}
                    className="btn-gradient rounded-xl gap-2"
                  >
                    <Download className="w-4 h-4" />
                    {language === 'pt' ? 'Baixar QR Code' : 'Download QR Code'}
                  </Button>
                </>
              ) : (
                <div className="text-center py-8">
                  <Wifi className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
                  <p className="text-muted-foreground">
                    {language === 'pt' 
                      ? 'Nenhuma senha WiFi cadastrada. Adicione em Senhas.' 
                      : 'No WiFi password registered. Add one in Passwords.'}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Markets Tab */}
        <TabsContent value="markets" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 font-display">
                <MapPin className="w-5 h-5 text-primary" />
                {language === 'pt' ? 'Mercados Próximos' : 'Nearby Markets'}
              </CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col items-center gap-4">
              <div className="bg-white p-4 rounded-2xl shadow-lg">
                <QRCodeSVG
                  id="markets-qr"
                  value={marketsUrl}
                  size={200}
                  level="M"
                  includeMargin
                />
              </div>
              <p className="text-sm text-muted-foreground text-center">
                {language === 'pt' 
                  ? 'Escaneie para ver mercados próximos no Google Maps' 
                  : 'Scan to see nearby markets on Google Maps'}
              </p>
              <div className="flex gap-2">
                <Button 
                  onClick={() => handleDownloadQR('markets-qr', 'mercados-qrcode.png')}
                  variant="outline"
                  className="rounded-xl gap-2"
                >
                  <Download className="w-4 h-4" />
                  {language === 'pt' ? 'Baixar' : 'Download'}
                </Button>
                <Button 
                  onClick={() => window.open(marketsUrl, '_blank')}
                  className="btn-gradient rounded-xl gap-2"
                >
                  <ExternalLink className="w-4 h-4" />
                  {language === 'pt' ? 'Abrir no Maps' : 'Open in Maps'}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
