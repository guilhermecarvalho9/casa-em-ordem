import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Home, MapPin, Building, Pencil, Save, X, Key, Users, Calendar } from 'lucide-react';

export function AddressPage() {
  const { language, members } = useApp();
  const [isEditing, setIsEditing] = useState(false);
  
  const [address, setAddress] = useState({
    street: 'Rua das Flores, 123',
    neighborhood: 'Centro',
    city: 'São Paulo',
    state: 'SP',
    zipCode: '01234-567',
    complement: 'Apartamento 42, Bloco B',
  });

  const [property, setProperty] = useState({
    type: language === 'pt' ? 'Apartamento' : 'Apartment',
    rooms: '3',
    bathrooms: '2',
    area: '85',
    rentDay: '5',
    contractStart: '2024-01-01',
    contractEnd: '2026-01-01',
    landlordName: 'Imobiliária ABC',
    landlordPhone: '(11) 3333-4444',
    landlordEmail: 'contato@imobiliariabc.com.br',
    notes: language === 'pt' 
      ? 'Portaria 24h. Estacionamento incluído. Pets permitidos até 10kg.'
      : '24h concierge. Parking included. Pets allowed up to 10kg.',
  });

  const handleSave = () => {
    setIsEditing(false);
  };

  const handleCancel = () => {
    setIsEditing(false);
  };

  const t = {
    title: language === 'pt' ? 'Endereço' : 'Address',
    addressInfo: language === 'pt' ? 'Informações do Endereço' : 'Address Information',
    propertyInfo: language === 'pt' ? 'Informações do Imóvel' : 'Property Information',
    contractInfo: language === 'pt' ? 'Informações do Contrato' : 'Contract Information',
    street: language === 'pt' ? 'Rua' : 'Street',
    neighborhood: language === 'pt' ? 'Bairro' : 'Neighborhood',
    city: language === 'pt' ? 'Cidade' : 'City',
    state: language === 'pt' ? 'Estado' : 'State',
    zipCode: language === 'pt' ? 'CEP' : 'Zip Code',
    complement: language === 'pt' ? 'Complemento' : 'Complement',
    propertyType: language === 'pt' ? 'Tipo de Imóvel' : 'Property Type',
    rooms: language === 'pt' ? 'Quartos' : 'Rooms',
    bathrooms: language === 'pt' ? 'Banheiros' : 'Bathrooms',
    area: language === 'pt' ? 'Área (m²)' : 'Area (sqft)',
    rentDay: language === 'pt' ? 'Dia do Vencimento' : 'Rent Due Day',
    contractStart: language === 'pt' ? 'Início do Contrato' : 'Contract Start',
    contractEnd: language === 'pt' ? 'Fim do Contrato' : 'Contract End',
    landlordName: language === 'pt' ? 'Proprietário/Imobiliária' : 'Landlord/Agency',
    landlordPhone: language === 'pt' ? 'Telefone' : 'Phone',
    landlordEmail: language === 'pt' ? 'Email' : 'Email',
    notes: language === 'pt' ? 'Observações' : 'Notes',
    edit: language === 'pt' ? 'Editar' : 'Edit',
    save: language === 'pt' ? 'Salvar' : 'Save',
    cancel: language === 'pt' ? 'Cancelar' : 'Cancel',
    residents: language === 'pt' ? 'Moradores' : 'Residents',
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t.title}</h1>
        {!isEditing ? (
          <Button className="btn-gradient rounded-xl" onClick={() => setIsEditing(true)}>
            <Pencil className="w-4 h-4 mr-2" />
            {t.edit}
          </Button>
        ) : (
          <div className="flex gap-2">
            <Button variant="outline" onClick={handleCancel}>
              <X className="w-4 h-4 mr-2" />
              {t.cancel}
            </Button>
            <Button className="btn-gradient" onClick={handleSave}>
              <Save className="w-4 h-4 mr-2" />
              {t.save}
            </Button>
          </div>
        )}
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* Address Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <MapPin className="w-5 h-5 text-primary" />
              {t.addressInfo}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>{t.street}</Label>
              {isEditing ? (
                <Input
                  value={address.street}
                  onChange={(e) => setAddress(prev => ({ ...prev, street: e.target.value }))}
                  className="input-field"
                />
              ) : (
                <p className="p-2 rounded-lg bg-secondary/50">{address.street}</p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>{t.neighborhood}</Label>
                {isEditing ? (
                  <Input
                    value={address.neighborhood}
                    onChange={(e) => setAddress(prev => ({ ...prev, neighborhood: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{address.neighborhood}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.city}</Label>
                {isEditing ? (
                  <Input
                    value={address.city}
                    onChange={(e) => setAddress(prev => ({ ...prev, city: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{address.city}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.state}</Label>
                {isEditing ? (
                  <Input
                    value={address.state}
                    onChange={(e) => setAddress(prev => ({ ...prev, state: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{address.state}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.zipCode}</Label>
                {isEditing ? (
                  <Input
                    value={address.zipCode}
                    onChange={(e) => setAddress(prev => ({ ...prev, zipCode: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{address.zipCode}</p>
                )}
              </div>
            </div>

            <div className="space-y-2">
              <Label>{t.complement}</Label>
              {isEditing ? (
                <Input
                  value={address.complement}
                  onChange={(e) => setAddress(prev => ({ ...prev, complement: e.target.value }))}
                  className="input-field"
                />
              ) : (
                <p className="p-2 rounded-lg bg-secondary/50">{address.complement}</p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Property Info Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <Home className="w-5 h-5 text-primary" />
              {t.propertyInfo}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>{t.propertyType}</Label>
                {isEditing ? (
                  <Input
                    value={property.type}
                    onChange={(e) => setProperty(prev => ({ ...prev, type: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.type}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.area}</Label>
                {isEditing ? (
                  <Input
                    value={property.area}
                    onChange={(e) => setProperty(prev => ({ ...prev, area: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.area} m²</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.rooms}</Label>
                {isEditing ? (
                  <Input
                    value={property.rooms}
                    onChange={(e) => setProperty(prev => ({ ...prev, rooms: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.rooms}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.bathrooms}</Label>
                {isEditing ? (
                  <Input
                    value={property.bathrooms}
                    onChange={(e) => setProperty(prev => ({ ...prev, bathrooms: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.bathrooms}</p>
                )}
              </div>
            </div>

            <div className="p-4 rounded-lg bg-primary/10 flex items-center gap-3">
              <Users className="w-5 h-5 text-primary" />
              <div>
                <p className="font-medium">{t.residents}</p>
                <p className="text-sm text-muted-foreground">{members.length} {language === 'pt' ? 'pessoas' : 'people'}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Contract Info Card */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <Building className="w-5 h-5 text-primary" />
              {t.contractInfo}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>{t.landlordName}</Label>
                {isEditing ? (
                  <Input
                    value={property.landlordName}
                    onChange={(e) => setProperty(prev => ({ ...prev, landlordName: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.landlordName}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.landlordPhone}</Label>
                {isEditing ? (
                  <Input
                    value={property.landlordPhone}
                    onChange={(e) => setProperty(prev => ({ ...prev, landlordPhone: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.landlordPhone}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.landlordEmail}</Label>
                {isEditing ? (
                  <Input
                    value={property.landlordEmail}
                    onChange={(e) => setProperty(prev => ({ ...prev, landlordEmail: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.landlordEmail}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Key className="w-4 h-4" />
                  {t.rentDay}
                </Label>
                {isEditing ? (
                  <Input
                    value={property.rentDay}
                    onChange={(e) => setProperty(prev => ({ ...prev, rentDay: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{language === 'pt' ? `Dia ${property.rentDay}` : `Day ${property.rentDay}`}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  {t.contractStart}
                </Label>
                {isEditing ? (
                  <Input
                    type="date"
                    value={property.contractStart}
                    onChange={(e) => setProperty(prev => ({ ...prev, contractStart: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.contractStart}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  {t.contractEnd}
                </Label>
                {isEditing ? (
                  <Input
                    type="date"
                    value={property.contractEnd}
                    onChange={(e) => setProperty(prev => ({ ...prev, contractEnd: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{property.contractEnd}</p>
                )}
              </div>
            </div>

            <div className="space-y-2">
              <Label>{t.notes}</Label>
              {isEditing ? (
                <Textarea
                  value={property.notes}
                  onChange={(e) => setProperty(prev => ({ ...prev, notes: e.target.value }))}
                  className="input-field min-h-24"
                />
              ) : (
                <p className="p-2 rounded-lg bg-secondary/50">{property.notes}</p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
