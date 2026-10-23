const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class Appointment extends Model {}

  Appointment.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    mother_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    doctor_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    slot_datetime: {
      type: DataTypes.DATE,
      allowNull: false
    },
    status: {
      type: DataTypes.STRING(20),
      defaultValue: 'pending'
    },
    alternative_time_suggested: {
      type: DataTypes.DATE
    },
    notes: {
      type: DataTypes.TEXT
    }
  }, {
    sequelize,
    modelName: 'Appointment',
    tableName: 'appointments',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  Appointment.associate = (models) => {
    Appointment.belongsTo(models.User, {
      foreignKey: 'mother_id',
      as: 'mother'
    });
    Appointment.belongsTo(models.User, {
      foreignKey: 'doctor_id',
      as: 'doctor'
    });
    Appointment.hasOne(models.ClinicalRecord, {
      foreignKey: 'appointment_id',
      as: 'clinicalRecord'
    });
  };

  return Appointment;
};
