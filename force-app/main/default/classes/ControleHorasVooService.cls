/**
 * Transactional domain service for flight logs and their fuel records.
 */
public without sharing class ControleHorasVooService {
    private static final Decimal MILLIS_PER_HOUR = 3600000;
    private static final Integer MILLIS_PER_DAY = 86400000;

    public class ControleHorasVooException extends Exception {}

    public class SaveRequest {
        public Controle_Horas_Voo__c controle;
        public Id controleOriginalId;
        public Boolean somenteAbastecimento;
        public Abastecimento__c abastecimentoAtual;
        public Id abastecimentoOriginalId;
        public List<Abastecimento__c> abastecimentos;
        public List<Id> abastecimentoIds;
    }

    public class SaveResult {
        public Id controleId;
        public Boolean updated;
        public Set<Id> aeronavesRecalculadas = new Set<Id>();
    }

    public static SaveResult save(SaveRequest request) {
        validateRequest(request);
        Savepoint savepoint = Database.setSavepoint();
        Boolean isUpdate = request.controleOriginalId != null;

        try {
            Controle_Horas_Voo__c original = isUpdate
                ? selectOriginalForUpdate(request.controleOriginalId)
                : null;

            normalizeFlight(request.controle, request.somenteAbastecimento == true);
            request.controle.Id = request.controleOriginalId;

            Set<Id> aircraftIds = new Set<Id>{ request.controle.Aeronave__c };
            if (original != null) {
                aircraftIds.add(original.Aeronave__c);
            }
            aircraftIds.remove(null);
            lockAircraft(aircraftIds);

            Controle_Horas_Voo__c writableFlight = (Controle_Horas_Voo__c)
                prepareWritableRecord(request.controle, isUpdate);
            if (isUpdate) {
                ControleHorasVooAuditService.updateEditedFlight(writableFlight);
            } else {
                Database.insert(writableFlight, AccessLevel.SYSTEM_MODE);
            }
            request.controle.Id = writableFlight.Id;

            saveFuelRecords(request, request.controle.Id, request.controle.Data_do_Voo__c);
            recalculateAircraftHours(aircraftIds);

            SaveResult result = new SaveResult();
            result.controleId = request.controle.Id;
            result.updated = isUpdate;
            result.aeronavesRecalculadas.addAll(aircraftIds);
            return result;
        } catch (Exception exceptionValue) {
            Database.rollback(savepoint);
            if (!isUpdate) {
                request.controle.Id = null;
            }
            throw userFacingException('salvar o controle de horas', exceptionValue);
        }
    }

    public static void deleteFlight(Id controleId) {
        if (controleId == null) {
            throw new ControleHorasVooException('Informe o voo que deve ser excluído.');
        }

        Savepoint savepoint = Database.setSavepoint();
        try {
            Controle_Horas_Voo__c flight = [
                SELECT Id, Aeronave__c
                FROM Controle_Horas_Voo__c
                WHERE Id = :controleId
                WITH SYSTEM_MODE
                LIMIT 1
                FOR UPDATE
            ];
            Set<Id> aircraftIds = new Set<Id>{ flight.Aeronave__c };
            aircraftIds.remove(null);
            lockAircraft(aircraftIds);

            Database.delete(flight, AccessLevel.SYSTEM_MODE);
            recalculateAircraftHours(aircraftIds);
        } catch (Exception exceptionValue) {
            Database.rollback(savepoint);
            throw userFacingException('excluir o voo', exceptionValue);
        }
    }

    @TestVisible
    private static void normalizeFlight(Controle_Horas_Voo__c flight, Boolean refuelOnly) {
        if (refuelOnly) {
            flight.Tipo__c = 'AB';
            flight.TOT__c = 0;
            flight.Horas_Voo__c = 0;
            return;
        }

        if (flight.Acionamento__c == null && flight.Corte__c == null) {
            return;
        }
        if (flight.Acionamento__c == null || flight.Corte__c == null) {
            throw new ControleHorasVooException(
                'Informe os horários de acionamento e corte para calcular as horas do voo.'
            );
        }

        Integer startMillis = toMillis(flight.Acionamento__c);
        Integer endMillis = toMillis(flight.Corte__c);
        Integer elapsedMillis = endMillis - startMillis;
        if (elapsedMillis < 0) {
            elapsedMillis += MILLIS_PER_DAY;
        }

        Decimal elapsedHours = Decimal.valueOf(elapsedMillis) / MILLIS_PER_HOUR;
        flight.TOT__c = elapsedHours.setScale(2);
        flight.Horas_Voo__c = elapsedHours.setScale(1);
    }

    private static void validateRequest(SaveRequest request) {
        if (request == null || request.controle == null) {
            throw new ControleHorasVooException('Os dados do controle de horas não foram informados.');
        }

        List<String> errors = new List<String>();
        Controle_Horas_Voo__c flight = request.controle;
        if (flight.Aeronave__c == null) errors.add('A aeronave é obrigatória.');
        if (flight.Piloto__c == null) errors.add('O piloto é obrigatório.');
        if (flight.Data_do_Voo__c == null) errors.add('A data do voo é obrigatória.');
        if (request.somenteAbastecimento != true && String.isBlank(flight.Tipo__c)) {
            errors.add('O tipo do voo é obrigatório.');
        }
        if (flight.Horas_Voo__c != null && flight.Horas_Voo__c < 0) {
            errors.add('As horas de voo não podem ser negativas.');
        }

        validateFuel(request.abastecimentoAtual, errors);
        if (request.abastecimentos != null) {
            for (Abastecimento__c fuel : request.abastecimentos) {
                validateFuel(fuel, errors);
            }
        }

        if (!errors.isEmpty()) {
            throw new ControleHorasVooException(String.join(errors, ' '));
        }
    }

    private static void validateFuel(Abastecimento__c fuel, List<String> errors) {
        if (fuel == null) return;
        if (fuel.Quantidade__c != null && fuel.Quantidade__c < 0) {
            errors.add('A quantidade de combustível não pode ser negativa.');
        }
        if (fuel.Custo_Unitario__c != null && fuel.Custo_Unitario__c < 0) {
            errors.add('O custo unitário do combustível não pode ser negativo.');
        }
    }

    private static Controle_Horas_Voo__c selectOriginalForUpdate(Id controleId) {
        return [
            SELECT Id, Aeronave__c
            FROM Controle_Horas_Voo__c
            WHERE Id = :controleId
            WITH SYSTEM_MODE
            LIMIT 1
            FOR UPDATE
        ];
    }

    private static void lockAircraft(Set<Id> aircraftIds) {
        if (aircraftIds.isEmpty()) return;
        List<Aeronave__c> lockedAircraft = [
            SELECT Id
            FROM Aeronave__c
            WHERE Id IN :aircraftIds
            WITH SYSTEM_MODE
            FOR UPDATE
        ];
    }

    private static void saveFuelRecords(SaveRequest request, Id flightId, Date flightDate) {
        if (request.abastecimentos != null && !request.abastecimentos.isEmpty()) {
            List<Abastecimento__c> inserts = new List<Abastecimento__c>();
            List<Abastecimento__c> updates = new List<Abastecimento__c>();
            for (Integer index = 0; index < request.abastecimentos.size(); index++) {
                Abastecimento__c fuel = request.abastecimentos[index];
                if (!hasFuelData(fuel)) continue;

                fuel.Voo__c = flightId;
                fuel.Data_Voo__c = flightDate;
                calculateFuelCost(fuel);
                Id existingId = request.abastecimentoIds != null
                    && index < request.abastecimentoIds.size()
                    ? request.abastecimentoIds[index]
                    : null;
                if (existingId == null) {
                    fuel.Id = null;
                    inserts.add(fuel);
                } else {
                    fuel.Id = existingId;
                    fuel.Editado_Manualmente__c = true;
                    updates.add(fuel);
                }
            }
            if (!updates.isEmpty()) {
                List<Abastecimento__c> writableUpdates =
                    castFuelRecords(prepareWritableRecords(updates, true));
                ControleHorasVooAuditService.updateEditedFuels(writableUpdates);
            }
            if (!inserts.isEmpty()) {
                Database.insert(
                    castFuelRecords(prepareWritableRecords(inserts, false)),
                    AccessLevel.SYSTEM_MODE
                );
            }
            return;
        }

        if (!hasFuelData(request.abastecimentoAtual)) return;
        Abastecimento__c fuel = request.abastecimentoAtual;
        fuel.Voo__c = flightId;
        fuel.Data_Voo__c = flightDate;
        fuel.Id = request.abastecimentoOriginalId;
        calculateFuelCost(fuel);
        if (fuel.Id == null) {
            Abastecimento__c writableFuel = (Abastecimento__c)
                prepareWritableRecord(fuel, false);
            Database.insert(writableFuel, AccessLevel.SYSTEM_MODE);
            fuel.Id = writableFuel.Id;
        } else {
            Abastecimento__c writableFuel = (Abastecimento__c)
                prepareWritableRecord(fuel, true);
            ControleHorasVooAuditService.updateEditedFuels(
                new List<Abastecimento__c>{ writableFuel }
            );
        }
    }

    private static Boolean hasFuelData(Abastecimento__c fuel) {
        return fuel != null
            && (fuel.Quantidade__c != null || fuel.Custo_Unitario__c != null);
    }

    private static void calculateFuelCost(Abastecimento__c fuel) {
        if (fuel.Quantidade__c != null && fuel.Custo_Unitario__c != null) {
            fuel.Custo_Total__c = fuel.Quantidade__c * fuel.Custo_Unitario__c;
        }
    }

    private static SObject prepareWritableRecord(SObject source, Boolean isUpdate) {
        if (source instanceof Controle_Horas_Voo__c) {
            Controle_Horas_Voo__c flight = (Controle_Horas_Voo__c) source;
            return new Controle_Horas_Voo__c(
                Id = isUpdate ? flight.Id : null,
                Aeronave__c = flight.Aeronave__c,
                Piloto__c = flight.Piloto__c,
                Operador__c = flight.Operador__c,
                Data_do_Voo__c = flight.Data_do_Voo__c,
                Tipo__c = flight.Tipo__c,
                Descricao__c = flight.Descricao__c,
                DEP__c = flight.DEP__c,
                ARR__c = flight.ARR__c,
                Acionamento__c = flight.Acionamento__c,
                Corte__c = flight.Corte__c,
                TOT__c = flight.TOT__c,
                Horas_Voo__c = flight.Horas_Voo__c,
                Notas__c = flight.Notas__c,
                Obs__c = flight.Obs__c,
                Faturado__c = flight.Faturado__c,
                Usuario_Alteracao__c = flight.Usuario_Alteracao__c,
                Contato_Alteracao__c = flight.Contato_Alteracao__c
            );
        }

        Abastecimento__c fuel = (Abastecimento__c) source;
        return new Abastecimento__c(
            Id = isUpdate ? fuel.Id : null,
            Voo__c = fuel.Voo__c,
            Data_Voo__c = fuel.Data_Voo__c,
            Quantidade__c = fuel.Quantidade__c,
            Custo_Unitario__c = fuel.Custo_Unitario__c,
            Custo_Total__c = fuel.Custo_Total__c,
            Tipo_Combustivel__c = fuel.Tipo_Combustivel__c,
            Unidade__c = fuel.Unidade__c,
            Local__c = fuel.Local__c,
            Origem_Destino__c = fuel.Origem_Destino__c,
            Documento_Referencia__c = fuel.Documento_Referencia__c,
            Observacoes__c = fuel.Observacoes__c,
            Faturado__c = fuel.Faturado__c
        );
    }

    private static List<SObject> prepareWritableRecords(
        List<Abastecimento__c> records,
        Boolean isUpdate
    ) {
        List<SObject> result = new List<SObject>();
        for (Abastecimento__c record : records) {
            result.add(prepareWritableRecord(record, isUpdate));
        }
        return result;
    }

    private static List<Abastecimento__c> castFuelRecords(List<SObject> records) {
        List<Abastecimento__c> result = new List<Abastecimento__c>();
        for (SObject record : records) {
            result.add((Abastecimento__c) record);
        }
        return result;
    }

    private static void recalculateAircraftHours(Set<Id> aircraftIds) {
        if (aircraftIds.isEmpty()) return;

        Map<Id, Decimal> totalsByAircraft = new Map<Id, Decimal>();
        for (AggregateResult result : [
            SELECT Aeronave__c aircraftId, SUM(Horas_Voo__c) total
            FROM Controle_Horas_Voo__c
            WHERE Aeronave__c IN :aircraftIds
              AND Tipo__c != 'AB'
            WITH SYSTEM_MODE
            GROUP BY Aeronave__c
        ]) {
            totalsByAircraft.put(
                (Id) result.get('aircraftId'),
                (Decimal) result.get('total')
            );
        }

        List<Aeronave__c> updates = new List<Aeronave__c>();
        for (Id aircraftId : aircraftIds) {
            updates.add(new Aeronave__c(
                Id = aircraftId,
                Horas_Totais_de_Voo__c = totalsByAircraft.containsKey(aircraftId)
                    ? totalsByAircraft.get(aircraftId)
                    : 0
            ));
        }
        Database.update(updates, AccessLevel.SYSTEM_MODE);
    }

    private static Integer toMillis(Time value) {
        return value.hour() * 60 * 60 * 1000
            + value.minute() * 60 * 1000
            + value.second() * 1000
            + value.millisecond();
    }

    private static ControleHorasVooException userFacingException(
        String operationName,
        Exception exceptionValue
    ) {
        if (exceptionValue instanceof ControleHorasVooException) {
            return new ControleHorasVooException(exceptionValue.getMessage());
        }
        if (exceptionValue instanceof DmlException) {
            DmlException dmlException = (DmlException) exceptionValue;
            String detail = dmlException.getNumDml() > 0
                ? dmlException.getDmlMessage(0)
                : 'Verifique os campos informados.';
            return new ControleHorasVooException('Não foi possível ' + operationName + '. ' + detail);
        }
        return new ControleHorasVooException(
            'Não foi possível ' + operationName + '. Tente novamente ou contate o suporte.'
        );
    }
}
